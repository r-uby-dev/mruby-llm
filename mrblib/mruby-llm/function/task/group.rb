# frozen_string_literal: true

class LLM::Function
  ##
  # Wraps an array of {LLM::Function::Task::Task} objects running
  # cooperatively through the mruby-task scheduler.
  class Task::Group < LLM::Function::Group
    ##
    # @param [Array<LLM::Function::Task::Task>] tasks
    # @return [LLM::Function::Task::Group]
    def initialize(tasks)
      @tasks = tasks
    end

    ##
    # @return [nil]
    def spawn
      @tasks.each(&:spawn)
      nil
    ensure
      @spawned = true
    end

    ##
    # @return [Boolean]
    def alive?
      @tasks.any?(&:alive?)
    end

    ##
    # @return [nil]
    def interrupt!
      @tasks.each(&:interrupt!)
      nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # @return [Array<LLM::Function::Return>]
    def wait
      spawn unless @spawned
      @tasks.map(&:wait)
    end
    alias_method :value, :wait
  end
end
