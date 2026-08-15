# frozen_string_literal: true

describe "LLM" do
  describe "key discovery" do
    let(:key_names) do
      %w[
        OPENAI_API_KEY ANTHROPIC_API_KEY GOOGLE_API_KEY GOOGLE_GENERATIVE_AI_API_KEY
        GEMINI_API_KEY DEEPSEEK_API_KEY DEEPINFRA_API_KEY XAI_API_KEY
        MISTRAL_API_KEY ZHIPU_API_KEY MOONSHOT_API_KEY DASHSCOPE_API_KEY
      ]
    end

    before do
      @saved_keys = {}
      key_names.each do |name|
        @saved_keys[name] = ENV[name]
        ENV.delete(name)
      end
    end

    after do
      @saved_keys.each do |name, value|
        value.nil? ? ENV.delete(name) : ENV[name] = value
      end
    end

    it "raises ArgumentError when no api key is set" do
      expect(proc { LLM.openai }).must_raise ArgumentError
    end

    it "raises a helpful message when no api key is set" do
      begin
        LLM.openai
      rescue ArgumentError => e
        expect(e.message).must_equal "you must provide an api key"
      end
    end

    it "discovers the api key from the environment" do
      ENV["OPENAI_API_KEY"] = "sk-discovered"
      llm = LLM.openai
      expect(llm).must_be_instance_of LLM::OpenAI
      expect(llm.key?).must_equal true
    end

    it "prefers an explicitly provided key" do
      llm = LLM.openai(key: "sk-explicit")
      expect(llm).must_be_instance_of LLM::OpenAI
      expect(llm.key?).must_equal true
    end

    it "discovers keys for every cloud provider" do
      ENV["ANTHROPIC_API_KEY"] = "sk-anthropic"
      expect(LLM.anthropic).must_be_instance_of LLM::Anthropic

      ENV["GOOGLE_API_KEY"] = "sk-google"
      expect(LLM.google).must_be_instance_of LLM::Google

      ENV["DEEPSEEK_API_KEY"] = "sk-deepseek"
      expect(LLM.deepseek).must_be_instance_of LLM::DeepSeek

      ENV["XAI_API_KEY"] = "sk-xai"
      expect(LLM.xai).must_be_instance_of LLM::XAI

      ENV["ZHIPU_API_KEY"] = "sk-zai"
      expect(LLM.zai).must_be_instance_of LLM::ZAI

      ENV["DEEPINFRA_API_KEY"] = "sk-deepinfra"
      expect(LLM.deepinfra).must_be_instance_of LLM::DeepInfra

      ENV["MOONSHOT_API_KEY"] = "sk-moonshot"
      expect(LLM.moonshot).must_be_instance_of LLM::Moonshot

      ENV["MISTRAL_API_KEY"] = "sk-mistral"
      expect(LLM.mistral).must_be_instance_of LLM::Mistral

      ENV["DASHSCOPE_API_KEY"] = "sk-alibaba"
      expect(LLM.alibaba).must_be_instance_of LLM::Alibaba
      expect(LLM.aliyun).must_be_instance_of LLM::Alibaba
    end

    it "keeps local providers on a nil key" do
      expect(LLM.ollama.key?).must_equal false
      expect(LLM.llamacpp.key?).must_equal false
    end
  end
end

Minitest.run(ARGV) || exit(1)
