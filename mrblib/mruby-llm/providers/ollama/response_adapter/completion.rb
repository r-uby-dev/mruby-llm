# frozen_string_literal: true

module LLM::Ollama::ResponseAdapter
  module Completion
    ##
    # (see LLM::Contract::Completion#messages)
    def messages
      adapt_choices
    end
    alias_method :choices, :messages

    ##
    # Returns the response body, parsing NDJSON when the
    # transport returned a raw string (non-streaming path).
    # @return [LLM::Object]
    def body
      raw = super
      return raw unless String === raw
      parse_ndjson(raw)
    end

    ##
    # (see LLM::Contract::Completion#input_tokens)
    def input_tokens
      body.prompt_eval_count || 0
    end

    ##
    # (see LLM::Contract::Completion#output_tokens)
    def output_tokens
      body.eval_count || 0
    end

    ##
    # (see LLM::Contract::Completion#reasoning_tokens)
    def reasoning_tokens
      0
    end

    ##
    # (see LLM::Contract::Completion#input_audio_tokens)
    def input_audio_tokens
      super
    end

    ##
    # (see LLM::Contract::Completion#output_audio_tokens)
    def output_audio_tokens
      super
    end

    ##
    # (see LLM::Contract::Completion#input_image_tokens)
    def input_image_tokens
      super
    end

    ##
    # (see LLM::Contract::Completion#cache_read_tokens)
    def cache_read_tokens
      0
    end

    ##
    # (see LLM::Contract::Completion#cache_write_tokens)
    def cache_write_tokens
      0
    end

    ##
    # (see LLM::Contract::Completion#total_tokens)
    def total_tokens
      input_tokens + output_tokens
    end

    ##
    # (see LLM::Contract::Completion#usage)
    def usage
      super
    end

    ##
    # (see LLM::Contract::Completion#model)
    def model
      body.model
    end

    ##
    # (see LLM::Contract::Completion#content)
    def content
      super
    end

    ##
    # (see LLM::Contract::Completion#reasoning_content)
    def reasoning_content
      super
    end

    ##
    # (see LLM::Contract::Completion#content!)
    def content!
      super
    end

    private

    def adapt_choices
      message = body.message
      role, content, calls = message.role, message.content, message.tool_calls
      extra = {response: self, tool_calls: adapt_tool_calls(calls)}
      [LLM::Message.new(role, content, extra)]
    end

    def adapt_tool_calls(tools)
      return [] unless tools
      tools.filter_map do |tool|
        next unless tool["function"]
        tool["function"]
      end
    end

    ##
    # Parses a raw NDJSON string into an LLM::Object.
    # Ollama's streaming API returns application/x-ndjson,
    # but the transport only parses application/json. When
    # the response body arrives as a raw string, we merge
    # the NDJSON lines here.
    # @param [String] raw
    # @return [LLM::Object]
    def parse_ndjson(raw)
      lines = raw.split("\n").reject(&:empty?)
      merged = lines.each_with_object({}) do |line, hash|
        parsed = LLM.json.load(line)
        next unless parsed.is_a?(Hash)
        parsed.each do |key, value|
          if key == "message" && value.is_a?(Hash)
            if hash.key?("message")
              hash["message"]["content"] << value["content"].to_s
            else
              hash["message"] = {"role" => value["role"], "content" => value["content"].to_s}
              hash["message"]["tool_calls"] = value["tool_calls"] if value.key?("tool_calls")
            end
          else
            hash[key] = value
          end
        end
      end
      LLM::Object.from(merged)
    end

    include LLM::Contract::Completion
  end
end
