# frozen_string_literal: true

class LLM::A2A::Card
  ##
  # Represents a single skill/capability of an agent.
  class Skill
    ##
    # @param [Hash] data
    def initialize(data)
      @data = LLM::Object.from(data)
    end

    ##
    # Returns the unique identifier for the skill.
    # @return [String]
    def id
      @data.id
    end

    ##
    # Returns the human-readable skill name.
    # @return [String]
    def name
      @data.name
    end

    ##
    # Returns the detailed skill description.
    # @return [String]
    def description
      @data.description
    end

    ##
    # Returns capability tags for the skill.
    # @return [Array<String>]
    def tags
      @data.tags || []
    end

    ##
    # Returns example prompts for the skill.
    # @return [Array<String>]
    def examples
      @data.examples || []
    end

    ##
    # Returns the supported input media types.
    # @return [Array<String>]
    def input_modes
      @data.inputModes || @data.input_modes || []
    end

    ##
    # Returns the supported output media types.
    # @return [Array<String>]
    def output_modes
      @data.outputModes || @data.output_modes || []
    end

    ##
    # @return [String]
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} @id=#{id.inspect} @name=#{name.inspect}>"
    end
  end
end
