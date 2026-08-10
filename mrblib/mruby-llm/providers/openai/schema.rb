# frozen_string_literal: true

class LLM::OpenAI
  ##
  # Fallback schema handling for OpenAI-compatible providers whose APIs
  # do not support the `json_schema` response format. Falls back to
  # `json_object` and injects a system message describing the schema —
  # which also satisfies the "messages must contain the word json"
  # requirement.
  # @api private
  module Schema
    private

    ##
    # @param [Hash] params
    # @return [Hash]
    def adapt_schema(params)
      return {} unless params && params[:schema]
      schema = params.delete(:schema)
      schema = schema.respond_to?(:object) ? schema.object : schema
      params[:messages] ||= []
      params[:messages] << LLM::Message.new(system_role, adapt_prompt(schema))
      {response_format: {type: "json_object"}}
    end

    ##
    # Build the system prompt that describes the schema.
    # @param [#to_s] schema
    # @return [String]
    def adapt_prompt(schema)
      "Respond with a single valid JSON object. " \
      "Do not include markdown, code fences, commentary, or any text outside the JSON object. " \
      "The JSON object must match this schema: " \
      "#{schema}"
    end
  end
end
