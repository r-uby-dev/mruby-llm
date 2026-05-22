# frozen_string_literal: true

class LLM::A2A::Card
  ##
  # Represents the service provider of an agent.
  class Provider
    ##
    # @param [Hash] data
    def initialize(data)
      @data = LLM::Object.from(data)
    end

    ##
    # Returns the provider website URL.
    # @return [String]
    def url
      @data.url
    end

    ##
    # Returns the provider organization name.
    # @return [String]
    def organization
      @data.organization
    end
  end
end
