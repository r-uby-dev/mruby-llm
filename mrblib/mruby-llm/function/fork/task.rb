# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Fork::Task} class wraps a fork-backed function call
  # and exchanges result messages with the child process.
  #
  # The child is spawned lazily in {#wait} or explicitly in {#spawn}.
  # Because mruby has no `Thread` and no `Process.trap`, interruption uses a
  # hard kill of the child's process group; {#wait} then re-raises
  # {LLM::Interrupt} when it detects the kill.
  class Fork::Task < LLM::Function::Task
    ##
    # @return [Integer, nil]
    attr_reader :pid

    ##
    # @param [LLM::Function] fn
    # @param [Hash] options
    # @option options [LLM::Tracer, nil] :tracer
    # @return [LLM::Function::Fork::Task]
    def initialize(fn, options = {})
      super
      @tracer = options.fetch(:tracer, nil)
      @ch = nil
      @pid = nil
      @spawned = false
      @waited = false
      @interrupted = false
    end

    ##
    # @return [LLM::Function::Fork::Task]
    def spawn
      return if @guarded
      @span = @tracer&.on_tool_start(
        id: @function.id, name: @function.name,
        arguments: @function.arguments, model: @function.model
      )
      @ch = chan(:json, lock: :file).tap(&:nonblock!)
      @pid = fork { Fork::Job.new(@function, @ch).call }
      @spawned = true
      self
    end

    ##
    # @return [Boolean]
    def alive?
      return false if @waited || !@pid
      result = Process.waitpid(@pid, Process::WNOHANG)
      @waited = !result.nil?
      !@waited
    rescue Errno::ECHILD
      @waited = true
      false
    end

    ##
    # @return [nil]
    def interrupt!
      return nil if @waited || @guarded
      @interrupted = true
      Process.kill("KILL", -@pid)
      nil
    rescue Errno::ESRCH, Errno::EINVAL
      Process.kill("KILL", @pid) rescue nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # @return [LLM::Function::Return]
    def wait
      return @guarded if @guarded
      spawn unless @spawned
      loop do
        begin
          kind, data = @ch.read
          kind = kind.to_sym
          case kind
          when :interrupt
            reap
            raise LLM::Interrupt
          when :result
            result = deserialize(data)
            reap
            @tracer&.on_tool_finish(result:, span: @span)
            return result
          else
            raise ArgumentError, "Unknown fork message: #{kind.inspect}"
          end
        rescue Chan::WaitReadable
          unless alive?
            reap
            raise LLM::Interrupt if @interrupted
            return error_return
          end
          sleep 0.001
        end
      end
    ensure
      reap
      @ch.close unless @ch.nil? || @ch.closed?
    end
    alias_method :value, :wait

    ##
    # @return [Class]
    def group_class
      LLM::Function::Fork::Group
    end

    private

    def deserialize(data)
      Return.new(data["id"] || data[:id], data["name"] || data[:name], symbolize(data["value"] || data[:value]))
    end

    # The chan serializes through JSON, which stringifies symbol keys. Walk
    # the value back to symbol keys so fork results match the sequential and
    # task strategies (and llm.rb, whose fork uses Marshal).
    def symbolize(value)
      case value
      when ::Hash
        value.each_with_object({}) { |(k, v), h| h[k.to_sym] = symbolize(v) }
      when ::Array
        value.map { |v| symbolize(v) }
      else
        value
      end
    end

    def error_return
      Return.new(@function.id, @function.name, {
        error: true,
        type: LLM::Error.name,
        message: "tool call did not produce a result"
      })
    end

    def reap
      return if @waited || @pid.nil?
      Process.waitpid(@pid)
      @waited = true
    rescue Errno::ECHILD
      @waited = true
    end
  end
end
