# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Fork::Job} class represents a single fork-backed
  # function call inside the child process.
  #
  # It is executed in the forked process and is responsible for running the
  # resolved tool instance and writing the final result back to the parent
  # process.
  #
  # mruby has no `Thread` and no `Process.trap`, so a cooperative child
  # interrupt (llm.rb's control channel) is not feasible: the parent
  # hard-kills the child and detects the interrupt in {Fork::Task#wait}.
  class Fork::Job
    ##
    # @param [LLM::Function] function
    # @param [Chan::Pipe] ch
    # @return [LLM::Function::Fork::Job]
    def initialize(function, ch)
      @function = function
      @ch = ch
    end

    ##
    # @return [void]
    def call
      Process.setpgid(0, 0)
      write([:result, call!])
    rescue LLM::Interrupt
      write([:interrupt])
    rescue => ex
      write([:result, error(ex)])
    ensure
      @ch.close unless @ch.closed?
      exit! 0
    end

    private

    # The chan is created with `nonblock!` in the parent, so the child
    # inherits a non-blocking write end. A result larger than the pipe
    # buffer raises {Chan::WaitWritable}; retry until the pipe drains so
    # large tool results are not silently dropped.
    def write(message)
      loop do
        @ch.write(message)
        break
      rescue Chan::WaitWritable
        sleep 0.001
      end
    end

    def call!
      runner = @function.runner
      kwargs = LLM::Hash.try_convert(@function.arguments) || @function.arguments
      kwargs = kwargs.transform_keys(&:to_sym) if Hash === kwargs
      value = Hash === kwargs && kwargs.empty? ? runner.call : runner.call(**kwargs)
      {id: @function.id, name: @function.name, value:}
    end

    def error(ex)
      {
        id: @function.id,
        name: @function.name,
        value: {error: true, type: ex.class.name, message: ex.message}
      }
    end
  end
end
