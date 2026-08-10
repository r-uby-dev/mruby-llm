# frozen_string_literal: true

class LLM::Guard
  ##
  # {LLM::Guard::Null LLM::Guard::Null} is a no-op guard. It never blocks
  # pending tool work and is the default guard used by
  # {LLM::Context LLM::Context}.
  class Null < self
    ##
    # @param [LLM::Function] function
    #  The pending function (ignored)
    # @param [Hash] opts
    #  Per-call options (ignored)
    # @return [nil]
    def call(function:, **opts)
      nil
    end
  end
end
