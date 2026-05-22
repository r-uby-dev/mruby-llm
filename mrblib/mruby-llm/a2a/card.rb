# frozen_string_literal: true

class LLM::A2A
  ##
  # Represents an A2A Agent Card -- a self-describing manifest for an
  # agent that provides metadata including the agent's identity,
  # capabilities, skills, supported communication methods, and security
  # requirements.
  #
  # Agent Cards are published at `/.well-known/agent-card.json` and
  # allow clients to discover an agent's capabilities before interacting.
  #
  # @example
  #   a2a = LLM::A2A.rest(url: "https://agent.example.com")
  #   card = a2a.card
  #   puts card.name          # => "GeoSpatial Route Planner Agent"
  #   puts card.description   # => "Provides advanced route planning..."
  #   card.skills.each { |s| puts "#{s.name}: #{s.description}" }
  class Card
    ##
    # @param [Hash] data The raw Agent Card JSON data
    def initialize(data)
      @data = LLM::Object.from(data)
    end

    ##
    # Returns a human-readable name for the agent.
    # @return [String]
    def name
      @data.name
    end

    ##
    # Returns a human-readable description of the agent.
    # @return [String]
    def description
      @data.description
    end

    ##
    # Returns the agent version.
    # @return [String]
    def version
      @data.version
    end

    ##
    # Returns the advertised A2A protocol version.
    # @return [String, nil]
    def protocol_version
      @data.protocolVersion || @data.protocol_version
    end

    ##
    # Returns the documentation URL, when present.
    # @return [String, nil]
    def documentation_url
      @data.documentationUrl || @data.documentation_url
    end

    ##
    # Returns the icon URL, when present.
    # @return [String, nil]
    def icon_url
      @data.iconUrl || @data.icon_url
    end

    ##
    # Returns the skills provided by the agent.
    # @return [Array<LLM::A2A::Card::Skill>]
    def skills
      @skills ||= (@data.skills || []).map { Skill.new(_1) }
    end

    ##
    # Returns the interfaces supported by the agent.
    # @return [Array<LLM::A2A::Card::Interface>]
    def interfaces
      @interfaces ||= (@data.supportedInterfaces || @data.supported_interfaces || []).map { Interface.new(_1) }
    end

    ##
    # Returns the optional capabilities declaration.
    # @return [LLM::A2A::Card::Capabilities, nil]
    def capabilities
      raw = @data.capabilities
      raw ? Capabilities.new(raw) : nil
    end

    ##
    # Returns the agent card signatures.
    # @return [Array<LLM::Object>]
    def signatures
      @signatures ||= (@data.signatures || []).map { LLM::Object.from(_1) }
    end

    ##
    # Returns the security scheme definitions.
    # @return [Hash<String, Hash>, nil]
    def security_schemes
      @data.securitySchemes || @data.security_schemes
    end

    ##
    # Returns the security requirements.
    # @return [Array<Hash>, nil]
    def security_requirements
      @data.security || @data.security_requirements
    end

    ##
    # Returns the declared provider information.
    # @return [LLM::A2A::Card::Provider, nil]
    def provider
      raw = @data.provider
      raw ? Provider.new(raw) : nil
    end

    ##
    # Returns the default input media types.
    # @return [Array<String>]
    def default_input_modes
      @data.defaultInputModes || @data.default_input_modes || []
    end

    ##
    # Returns the default output media types.
    # @return [Array<String>]
    def default_output_modes
      @data.defaultOutputModes || @data.default_output_modes || []
    end

    ##
    # @return [String]
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} @name=#{name.inspect} @skills=#{skills.size}>"
    end
  end
end
