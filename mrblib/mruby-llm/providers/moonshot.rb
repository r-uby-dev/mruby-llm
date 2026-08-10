# frozen_string_literal: true

module LLM
  ##
  # The Moonshot class implements a provider for
  # [Moonshot AI](https://platform.moonshot.ai) through its
  # OpenAI-compatible Kimi API.
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require "llm"
  #
  #   llm = LLM.moonshot(key: ENV["KEY"])
  #   ctx = LLM::Context.new(llm)
  #   ctx.talk "Hello"
  class Moonshot < OpenAI
    HOST = "api.moonshot.ai"
    BASE_PATH = "/v1"

    ##
    # @param key (see LLM::Provider#initialize)
    # @param host (see LLM::Provider#initialize)
    # @param base_path (see LLM::Provider#initialize)
    # @return [LLM::Moonshot]
    def initialize(host: HOST, base_path: BASE_PATH, **)
      super(host:, base_path:, **)
    end

    ##
    # @return [Symbol]
    #  Returns the provider's name
    def name
      :moonshot
    end

    ##
    # @raise [NotImplementedError]
    def images
      raise NotImplementedError
    end

    ##
    # @raise [NotImplementedError]
    def audio
      raise NotImplementedError
    end

    ##
    # @raise [NotImplementedError]
    def moderations
      raise NotImplementedError
    end

    ##
    # @raise [NotImplementedError]
    def responses
      raise NotImplementedError
    end

    ##
    # @raise [NotImplementedError]
    def vector_stores
      raise NotImplementedError
    end

    ##
    # Returns the default model for chat completions
    # @see https://platform.moonshot.ai/docs/api/models-overview Kimi models
    # @return [String]
    def default_model
      "kimi-k3"
    end
  end
end
