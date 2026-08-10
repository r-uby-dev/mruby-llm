# frozen_string_literal: true

describe "LLM::Transformer" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:provider) { LLM.openai(key: "test-key", transport:) }
  let(:transformer_class) do
    Class.new(LLM::Transformer) do
      def call(message:, suffix:)
        LLM::Message.new(message.role, "#{message.content} #{suffix}", message.extra)
      end
    end
  end
  let(:stream_class) do
    Class.new(LLM::Stream) do
      attr_reader :events

      def initialize
        @events = []
      end

      def on_transform(transformer)
        @events << [:start, transformer]
      end

      def on_transform_finish(transformer)
        @events << [:finish, transformer]
      end
    end
  end
  let(:stream) { stream_class.new }

  describe "LLM::Transformer::Null" do
    let(:ctx) { LLM::Context.new(provider, model: "gpt-4.1") }

    it "is the default transformer" do
      expect(ctx.transformer).must_equal LLM::Transformer::Null
    end

    it "returns the message unchanged" do
      message = LLM::Message.new("user", "hello")
      result = LLM::Transformer::Null.new(ctx).call(message: message)
      expect(result).must_be_same_as message
    end
  end

  describe "when configured with a transformer" do
    let(:ctx) do
      LLM::Context.new(
        provider,
        model: "gpt-4.1",
        transformer: transformer_class,
        transformer_options: {suffix: "[scrubbed]"}
      )
    end

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
    end

    it "rewrites the most recent message before talk" do
      ctx.talk("hello")
      expect(ctx.messages[0].content).must_equal "hello [scrubbed]"
      expect(ctx.messages[1].content).must_equal "Hello from fixture"
    end

    it "passes transformer_options to call" do
      ctx.talk("hello")
      expect(ctx.messages[0].content).must_equal "hello [scrubbed]"
    end
  end

  describe "stream lifecycle callbacks" do
    let(:ctx) do
      LLM::Context.new(
        provider,
        model: "gpt-4.1",
        transformer: transformer_class,
        transformer_options: {suffix: "[scrubbed]"}
      )
    end

    before do
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions.sse",
        headers: {"content-type" => "text/event-stream"}
      )
      ctx.talk("hello", stream:)
    end

    it "notifies the stream when transform starts" do
      expect(stream.events.first.first).must_equal :start
      expect(stream.events.first.last).must_be_instance_of transformer_class
    end

    it "notifies the stream when transform finishes" do
      expect(stream.events.last.first).must_equal :finish
      expect(stream.events.last.last).must_be_instance_of transformer_class
    end
  end

  describe "when given an agent" do
    it "unwraps the agent context" do
      agent = LLM::Agent.new(provider, model: "gpt-4.1")
      expect(LLM::Transformer::Null.new(agent).ctx).must_equal agent.instance_variable_get(:@ctx)
    end
  end

  describe "context params copy" do
    it "does not mutate the caller's params hash" do
      params = {mode: :completions, model: "gpt-4.1", transformer: transformer_class}
      LLM::Context.new(provider, params)
      expect(params.key?(:mode)).must_equal true
      expect(params.key?(:model)).must_equal true
      expect(params.key?(:transformer)).must_equal true
    end

    it "does not mutate the caller's params hash through an agent" do
      params = {model: "gpt-4.1", tools: []}
      LLM::Agent.new(provider, params)
      expect(params.key?(:model)).must_equal true
      expect(params.key?(:tools)).must_equal true
    end
  end
end

Minitest.run(ARGV) || exit(1)
