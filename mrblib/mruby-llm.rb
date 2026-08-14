# frozen_string_literal: true

module LLM
  @monitors = {require: ::Monitor.new, inherited: ::Monitor.new, registry: ::Monitor.new, mcp: ::Monitor.new}
  @registry = {}

  ##
  # @api private
  UNDEFINED = Object.new

  def self.registry_for(llm)
    lock(:registry) do
      name = Symbol === llm ? llm : llm.name
      @registry[name] ||= Registry.for(name)
    end
  end

  def self.json
    LLM::JSON
  end

  def self.function(key, &b)
    LLM::Function.new(key, &b)
  end

  def self.anthropic(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::Anthropic.new(key: key(name: __method__), **)
    else
      LLM::Anthropic.new(key:, **)
    end
  end

  def self.google(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::Google.new(key: key(name: __method__), **)
    else
      LLM::Google.new(key:, **)
    end
  end

  def self.ollama(key: nil, **)
    LLM::Ollama.new(key:, **)
  end

  def self.llamacpp(key: nil, **)
    LLM::LlamaCpp.new(key:, **)
  end

  def self.deepseek(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::DeepSeek.new(key: key(name: __method__), **)
    else
      LLM::DeepSeek.new(key:, **)
    end
  end

  def self.openai(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::OpenAI.new(key: key(name: __method__), **)
    else
      LLM::OpenAI.new(key:, **)
    end
  end

  def self.xai(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::XAI.new(key: key(name: __method__), **)
    else
      LLM::XAI.new(key:, **)
    end
  end

  def self.zai(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::ZAI.new(key: key(name: __method__), **)
    else
      LLM::ZAI.new(key:, **)
    end
  end

  def self.deepinfra(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::DeepInfra.new(key: key(name: __method__), **)
    else
      LLM::DeepInfra.new(key:, **)
    end
  end

  def self.moonshot(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::Moonshot.new(key: key(name: __method__), **)
    else
      LLM::Moonshot.new(key:, **)
    end
  end

  def self.alibaba(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::Alibaba.new(key: key(name: :alibaba), **)
    else
      LLM::Alibaba.new(key:, **)
    end
  end

  def self.aliyun(**)
    alibaba(**)
  end

  def self.mistral(key: UNDEFINED, **)
    if key == UNDEFINED
      LLM::Mistral.new(key: key(name: __method__), **)
    else
      LLM::Mistral.new(key:, **)
    end
  end

  def self.mcp(**)
    LLM::MCP.new(**)
  end

  ##
  # @param [LLM::Provider] llm
  #  A provider
  # @param [Hash] params
  #  Forwarded to LLM::Tracer::Logger
  # @return [LLM::Tracer::Logger]
  def self.logger(llm, **params)
    LLM::Tracer::Logger.new(llm, params)
  end

  def self.lock(name, &)
    @monitors[name].synchronize(&)
  end

  ##
  # Resolves a provider's API key from the environment.
  # @api private
  # @param [Symbol] name
  #  The provider name.
  # @raise [ArgumentError]
  #  When no registered env var is set.
  # @return [String]
  def self.key(name:)
    registry = LLM::Registry.for(name)
    keyname  = registry.env.find { ENV.key?(_1) }
    if keyname.nil?
      raise ArgumentError, "you must provide an api key"
    end
    ENV[keyname]
  end
end
