# frozen_string_literal: true

describe "LLM::Alibaba" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.alibaba(key: "test-key", transport:) }

  before do
    @saved_keys = {}
    %w[ALIBABA_API_KEY ALIBABA_API_HOST DASHSCOPE_API_KEY DASHSCOPE_API_HOST].each do |name|
      @saved_keys[name] = ENV[name]
      ENV.delete(name)
    end
  end

  after do
    @saved_keys.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end
  end

  it "builds the Alibaba provider with its API defaults" do
    expect(LLM::OpenAI === llm).must_equal true
    expect(llm.name).must_equal :alibaba
    expect(llm.default_model).must_equal "deepseek-v4-flash-0731"
    expect(llm.instance_variable_get(:@host)).must_equal "dashscope-intl.aliyuncs.com"
    expect(llm.instance_variable_get(:@base_path)).must_equal "/compatible-mode/v1"
  end

  it "aliases the provider through LLM.aliyun" do
    expect(LLM.aliyun(key: "test-key", transport:)).must_be_instance_of LLM::Alibaba
  end

  context "when completing" do
    let(:res) { llm.complete("ping") }
    let(:request) do
      res
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }

    before do
      transport.stub("POST", "/compatible-mode/v1/chat/completions", fixture: "alibaba/chat_completions.json")
    end

    it "sends chat completions to the Model Studio endpoint" do
      expect(request[:path]).must_equal "/compatible-mode/v1/chat/completions"
      expect(payload["model"]).must_equal "deepseek-v4-flash-0731"
      expect(res.content).must_equal "Hello from Alibaba"
    end
  end

  context "when completing with a schema" do
    let(:schema) { {type: "object", properties: {answer: {type: "string"}}, required: ["answer"]} }
    let(:request) do
      llm.complete("ping", schema:)
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }

    before do
      transport.stub("POST", "/compatible-mode/v1/chat/completions", fixture: "alibaba/chat_completions.json")
    end

    it "falls back to json_object with an injected system message" do
      expect(payload["response_format"]).must_equal({"type" => "json_object"})
      messages = payload["messages"]
      expect(messages[0]["role"]).must_equal "system"
      expect(messages[0]["content"][0]["text"]).must_match(/JSON object/)
    end
  end

  it "does not expose unsupported OpenAI APIs" do
    %i[images audio moderations responses vector_stores].each do |api|
      expect { llm.public_send(api) }.must_raise NotImplementedError
    end
  end
end

Minitest.run(ARGV) || exit(1)
