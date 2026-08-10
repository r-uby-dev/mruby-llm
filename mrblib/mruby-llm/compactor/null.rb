# frozen_string_literal: true

class LLM::Compactor
  ##
  # An {LLM::Compactor::Null LLM::Compactor::Null} is a compactor that
  # does nothing. It is used as the default when no compactor strategy
  # is configured.
  #
  # All methods return nil and produce no side effects.
  class Null < self
    ##
    # @param [Hash] opts
    #  Ignored
    # @return [nil]
    def call(**opts)
      nil
    end
  end
end
