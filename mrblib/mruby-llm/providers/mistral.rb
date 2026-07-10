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
    # Runs OCR on a remote image or document URL.
    # @see https://docs.mistral.ai/api/endpoint/ocr#operation-ocr_v1_ocr_post Mistral OCR docs
    # @param [String, nil] image_url
    #  A remote HTTP(S) URL to the image
    # @param [String, nil] document_url
    #  A remote HTTP(S) URL to the document
    # @param [String] model
    #  The OCR model to use
    # @param [Hash] params
    #  Additional OCR parameters
    # @raise [ArgumentError]
    #  When both or neither of image_url and document_url are provided
    # @return [LLM::Response]
    def ocr(image_url: nil, document_url: nil, model: "mistral-ocr-latest", **params)
      if [image_url, document_url].all?(&:nil?)
        raise ArgumentError, "must provide one of: image_url, document_url"
      elsif [image_url, document_url].compact.size > 1
        raise ArgumentError, "must provide one of: image_url, document_url"
      end
      document = parse_document(image_url, document_url)
      req = LLM::Transport::Request.post(path("/ocr"), headers)
      req.body = LLM.json.dump({model:, document:}.merge!(params))
      res, = execute(request: req, operation: "ocr", model:)
      LLM::Response.new(res)
    end

    ##
    # Returns the default model for chat completions
    # @return [String]
    def default_model
      "mistral-large-latest"
    end

    private

    ##
    # @api private
    def parse_document(image_url, document_url)
      if image_url
        {type: "image_url", image_url:}
      elsif document_url
        {type: "document_url", document_url:}
      end
    end
  end
end
