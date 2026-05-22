# frozen_string_literal: true

class LLM::A2A::Card
  ##
  # Represents a protocol interface supported by the agent.
  class Interface
    ##
    # @param [Hash] data
    def initialize(data)
      @data = LLM::Object.from(data)
    end

    ##
    # Returns the interface URL.
    # @return [String]
    def url
      @data.url
    end

    ##
    # Returns the protocol binding name.
    # @return [String]
    def protocol_binding
      @data.protocolBinding || @data.protocol_binding
    end

    ##
    # Returns the A2A protocol version.
    # @return [String]
    def protocol_version
      @data.protocolVersion || @data.protocol_version
    end
  end
end
