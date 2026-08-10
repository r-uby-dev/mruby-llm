# frozen_string_literal: true

describe "LLM::Moonshot" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.moonshot(key: "test-key", transport:) }

  it "builds the Moonshot provider with its API defaults" do
    expect(LLM::OpenAI === llm).must_equal true
    expect(llm.name).must_equal :moonshot
    expect(llm.default_model).must_equal "kimi-k3"
    expect(llm.instance_variable_get(:@host)).must_equal "api.moonshot.ai"
    expect(llm.instance_variable_get(:@base_path)).must_equal "/v1"
  end

  context "when completing" do
    let(:res) { llm.complete("ping") }
    let(:request) do
      res
      transport.requests[0]
    end
    let(:payload) { LLM.json.load(request[:body]) }

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "moonshot/chat_completions.json")
    end

    it "sends chat completions to the Kimi endpoint" do
      expect(request[:path]).must_equal "/v1/chat/completions"
      expect(payload["model"]).must_equal "kimi-k3"
      expect(res.content).must_equal "Hello from Moonshot"
    end
  end

  it "does not expose unsupported OpenAI APIs" do
    %i[images audio moderations responses vector_stores].each do |api|
      expect { llm.public_send(api) }.must_raise NotImplementedError
    end
  end
end

Minitest.run(ARGV) || exit(1)
