# frozen_string_literal: true

class LLM::A2A::Card
  ##
  # Represents the agent's optional capabilities.
  class Capabilities
    ##
    # @param [Hash] data
    def initialize(data)
      @data = LLM::Object.from(data)
    end

    ##
    # Returns whether the agent supports streaming.
    # @return [Boolean]
    def streaming
      @data.streaming == true
    end

    ##
    # Returns whether the agent supports push notifications.
    # @return [Boolean]
    def push_notifications
      @data.pushNotifications == true
    end

    ##
    # Returns whether the agent exposes an extended card.
    # @return [Boolean]
    def extended_agent_card
      @data.extendedAgentCard == true
    end

    ##
    # Returns the declared agent extensions.
    # @return [Array<LLM::Object>]
    def extensions
      @extensions ||= (@data.extensions || []).map { LLM::Object.from(_1) }
    end
  end
end
