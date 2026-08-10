# frozen_string_literal: true

class LLM::Transformer
  ##
  # An {LLM::Transformer::Null LLM::Transformer::Null} is a
  # transformer that does nothing. It is used as the default when
  # no transformer strategy is configured.
  #
  # It returns the given message unchanged.
  class Null < self
    ##
    # @param [LLM::Message] message
    #  The message to transform
    # @param [Hash] opts
    #  Ignored
    # @return [LLM::Message]
    def call(message:, **opts)
      message
    end
  end
end
