# frozen_string_literal: true

class LLM::Function
  ##
  # Abstract base class for all concurrency strategy groups.
  # Each strategy (sequential, task, fork) subclasses this and
  # implements {#alive?}, {#interrupt!}, and {#wait}.
  class Group
    ##
    # @abstract
    # @return [nil]
    def spawn
      raise NotImplementedError
    end

    ##
    # @abstract
    # @return [Boolean]
    def alive?
      raise NotImplementedError
    end

    ##
    # @abstract
    # @return [nil]
    def interrupt!
      raise NotImplementedError
    end
    alias_method :cancel!, :interrupt!

    ##
    # @abstract
    # @return [Array<LLM::Function::Return>]
    def wait
      raise NotImplementedError
    end
    alias_method :value, :wait
  end
end
