# frozen_string_literal: true

module LLM
  ##
  # The Alibaba class implements a provider for
  # [Alibaba Cloud Model Studio](https://www.alibabacloud.com/help/en/model-studio/models)
  # through its OpenAI-compatible API, including the Qwen3
  # family of models.
  #
  # The default host is the pay-as-you-go DashScope
  # international endpoint (`dashscope-intl.aliyuncs.com`). Configure
  # a different host either globally through the `ALIBABA_API_HOST`
  # environment variable, or per instance through
  # `LLM.alibaba(host: "token-plan.ap-southeast-1.maas.aliyuncs.com")`
  # (for example Alibaba's Token Plan).
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require "llm"
  #
  #   llm = LLM.alibaba(key: ENV["ALIBABA_API_KEY"])
  #   ctx = LLM::Context.new(llm)
  #   ctx.talk "Hello"
  class Alibaba < OpenAI
    HOST = "dashscope-intl.aliyuncs.com"
    BASE_PATH = "/compatible-mode/v1"

    ##
    # @param key (see LLM::Provider#initialize)
    # @param host (see LLM::Provider#initialize)
    # @param base_path (see LLM::Provider#initialize)
    # @return [LLM::Alibaba]
    def initialize(host: ENV.fetch("ALIBABA_API_HOST", HOST), base_path: BASE_PATH, **)
      super(host:, base_path:, **)
    end

    ##
    # @return [Symbol]
    #  Returns the provider's name
    def name
      :alibaba
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
    # @see https://www.alibabacloud.com/help/en/model-studio/models Qwen models
    # @return [String]
    def default_model
      "deepseek-v4-flash-0731"
    end
  end
end
