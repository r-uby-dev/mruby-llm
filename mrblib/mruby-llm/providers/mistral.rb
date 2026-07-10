# frozen_string_literal: true

module LLM
  ##
  # The Mistral class implements a provider for
  # [Mistral](https://mistral.ai) through its
  # OpenAI-compatible API.
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require "llm"
  #
  #   llm = LLM.mistral(key: ENV["KEY"])
  #   ctx = LLM::Context.new(llm)
  #   ctx.talk "Hello"
  #   ctx.messages.select(&:assistant?).each { print "[#{_1.role}]", _1.content, "\n" }
  class Mistral < OpenAI
    include LLM::Mistral::RequestAdapter
    HOST = "api.mistral.ai"

    ##
    # @param (see LLM::Provider#initialize)
    # @return [LLM::Mistral]
    def initialize(host: HOST, base_path: "/v1", **)
      super
    end

    ##
    # @return [Symbol]
    #  Returns the provider's name
    def name
      :mistral
    end

    ##
    # Provides an embedding.
    # @param input (see LLM::Provider#embed)
    # @param model (see LLM::Provider#embed)
    # @param params (see LLM::Provider#embed)
    # @raise (see LLM::Provider#request)
    # @return (see LLM::Provider#embed)
    def embed(input, model: "mistral-embed", **params)
      super
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
    def files
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
    # @return [String]
    def default_model
      "mistral-large-latest"
    end
  end
end
