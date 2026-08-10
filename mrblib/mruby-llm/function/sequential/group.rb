# frozen_string_literal: true

module LLM::Function::Sequential
  ##
  # Wraps an array of {LLM::Function::Sequential::Task} objects for
  # sequential execution. Provides the same interface as concurrent group
  # wrappers so callers can flow through `task(strategy).wait` uniformly.
  class Group < LLM::Function::Group
    ##
    # @param [Array<LLM::Function::Sequential::Task>] tasks
    # @return [LLM::Function::Sequential::Group]
    def initialize(tasks)
      @tasks = tasks
    end

    ##
    # @return [nil]
    def spawn
      @tasks.each(&:spawn)
      nil
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
      @tasks.map(&:wait)
    end
    alias_method :value, :wait
  end
end
