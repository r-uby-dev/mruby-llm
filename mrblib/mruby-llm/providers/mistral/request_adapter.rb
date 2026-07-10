# frozen_string_literal: true

class LLM::Mistral < LLM::OpenAI
  ##
  # @private
  module RequestAdapter
    ##
    # @param [Array<LLM::Message>] messages
    #  The messages to adapt
    # @return [Array<Hash>]
    def adapt(messages, mode: nil)
      messages.filter_map do |message|
        Completion.new(message).adapt
      end
    end
  end
end
