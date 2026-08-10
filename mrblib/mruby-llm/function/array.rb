# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Array} module extends the array
  # returned by {LLM::Context#functions} with methods
  # that can call all pending functions sequentially or
  # concurrently. The return values can be reported back
  # to the LLM on the next turn.
  module Array
    ##
    # Calls all functions in a collection sequentially.
    # @return [Array<LLM::Function::Return>]
    #  Returns values to be reported back to the LLM.
    def call
      map(&:call)
    end

    ##
    # Calls all functions in a collection concurrently.
    # This method returns an execution group that can be
    # waited on to access the return values.
    #
    # @param [Symbol] strategy
    #   Controls concurrency strategy:
    #   - `:sequential`: Call functions sequentially without spawning
    #   - `:task`: Run functions cooperatively through the mruby-task scheduler
    #   - `:fork`: Use forked child processes
    # @return [LLM::Function::Sequential::Group, LLM::Function::Task::Group, LLM::Function::Fork::Group]
    def task(strategy)
      case strategy
      when :sequential
        Sequential::Group.new(map { _1.task(:sequential) })
      when :task
        Task::Group.new(map { |fn| fn.task(:task) })
      when :fork
        Fork::Group.new(map { |fn| fn.task(:fork) })
      else
        raise ArgumentError, "Unknown strategy: #{strategy.inspect}. Expected :sequential, :task, or :fork"
      end
    end

    ##
    # Spawns a function collection through the legacy surface.
    # @deprecated Use {#task} instead.
    # @param [Symbol] strategy
    # @return [LLM::Function::Group]
    def spawn(strategy = :sequential)
      task(strategy)
    end

    ##
    # Calls all functions in a collection concurrently and waits for the
    # return values.
    #
    # @param [Symbol] strategy
    #   Controls concurrency strategy:
    #   - `:sequential`: Call functions sequentially without spawning
    #   - `:task`: Run functions cooperatively through the mruby-task scheduler
    #   - `:fork`: Use forked child processes
    # @return [Array<LLM::Function::Return>]
    #  Returns values to be reported back to the LLM.
    def wait(strategy)
      task(strategy).wait
    end

    ##
    # @return [LLM::Function::Array]
    def -(other)
      super(other).extend(Array)
    end
  end
end
