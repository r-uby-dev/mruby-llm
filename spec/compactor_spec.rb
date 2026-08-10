# frozen_string_literal: true

describe "LLM::Compactor" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:provider) { LLM.openai(key: "test-key", transport:) }

  def add_message(ctx, role, content, extra = {})
    ctx.messages << LLM::Message.new(role, content, extra)
  end

  def add_tool_call(ctx, name, args = {})
    add_message ctx, "assistant", "", {tool_calls: [{id: "call_1", name:, arguments: args}]}
  end

  describe "LLM::Compactor::Null" do
    let(:ctx) { LLM::Context.new(provider) }

    it "is the default compactor" do
      expect(ctx.compactor).must_equal LLM::Compactor::Null
    end

    it "does nothing" do
      expect(LLM::Compactor::Null.new(ctx).call).must_be_nil
    end
  end

  describe "LLM::Compactor::Truncate" do
    let(:ctx) { LLM::Context.new(provider) }
    let(:compactor) { LLM::Compactor::Truncate.new(ctx) }

    context "when the conversation is shorter than keep" do
      before do
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
      end

      it "returns nil" do
        expect(compactor.call(keep: 5)).must_be_nil
      end

      it "does not change the messages" do
        compactor.call(keep: 5)
        expect(ctx.messages.map(&:content)).must_equal %w[first second]
      end

      it "does not mark the context as compacted" do
        compactor.call(keep: 5)
        expect(ctx.compacted?).must_be_nil
      end
    end

    context "when the conversation exceeds keep" do
      before do
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
        add_message ctx, "user", "third"
        add_message ctx, "assistant", "fourth"
        add_message ctx, "user", "fifth"
      end

      it "drops the oldest non-system messages" do
        compactor.call(keep: 3)
        expect(ctx.messages.map(&:content)).must_equal %w[third fourth fifth]
      end

      it "returns the last N messages" do
        expect(compactor.call(keep: 3).map(&:content)).must_equal %w[third fourth fifth]
      end

      it "marks the context as compacted" do
        compactor.call(keep: 3)
        expect(ctx.compacted?).must_equal true
      end
    end

    context "when keep is a percentage string" do
      before do
        10.times { |i| add_message ctx, "user", "msg #{i}" }
      end

      it "keeps the specified percentage of messages" do
        result = compactor.call(keep: "50%")
        expect(result.size).must_equal 5
        expect(result.first.content).must_equal "msg 5"
      end

      it "rounds fractional percentages" do
        result = compactor.call(keep: "33%")
        expect(result.size).must_equal 3
      end

      it "returns nil when percentage rounds to zero" do
        expect(compactor.call(keep: "0%")).must_be_nil
      end
    end

    context "when keep is a string integer" do
      before do
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
        add_message ctx, "user", "third"
      end

      it "parses it as an integer" do
        expect(compactor.call(keep: "2").map(&:content)).must_equal %w[second third]
      end
    end

    context "when system messages are present" do
      before do
        add_message ctx, "system", "You are helpful"
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
        add_message ctx, "user", "third"
        add_message ctx, "assistant", "fourth"
      end

      it "preserves system messages and the last N" do
        compactor.call(keep: 2)
        expect(ctx.messages.map(&:content)).must_equal ["You are helpful", "third", "fourth"]
      end

      it "does not count system messages toward keep" do
        compactor.call(keep: 1)
        expect(ctx.messages.size).must_equal 2
        expect(ctx.messages.last.content).must_equal "fourth"
      end
    end

    context "when there are no non-system messages" do
      before { add_message ctx, "system", "You are helpful" }

      it "returns nil" do
        expect(compactor.call).must_be_nil
      end
    end

    context "when exactly keep non-system messages exist" do
      before do
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
        add_message ctx, "user", "third"
      end

      it "compacts with strict threshold" do
        expect(compactor.call(keep: 3).map(&:content)).must_equal %w[first second third]
      end
    end

    context "when tool calls span the truncation boundary" do
      before do
        add_message ctx, "user", "weather?"
        add_tool_call ctx, "get_forecast", location: "NYC"
        add_message ctx, "tool", LLM::Function::Return.new("call_1", "get_forecast", "72°F")
        add_message ctx, "assistant", "It's 72°F"
        add_message ctx, "user", "and in Chicago?"
      end

      it "keeps tool_call with its return at the boundary" do
        result = compactor.call(keep: 3)
        expect(result.count(&:tool_call?)).must_equal 1
        expect(result.count(&:tool_return?)).must_equal 1
      end

      it "preserves the tool call before its return" do
        result = compactor.call(keep: 3)
        call_idx = result.index(&:tool_call?)
        ret_idx  = result.index(&:tool_return?)
        if call_idx && ret_idx
          expect(call_idx < ret_idx).must_equal true
        end
      end
    end

    context "stream lifecycle" do
      let(:stream) do
        Class.new(LLM::Stream) do
          attr_reader :events

          def initialize
            @events = []
          end

          def on_compaction(compactor)
            @events << [:start, compactor]
          end

          def on_compaction_finish(compactor)
            @events << [:finish, compactor]
          end
        end.new
      end
      let(:ctx) { LLM::Context.new(provider, stream:) }

      before do
        add_message ctx, "user", "first"
        add_message ctx, "assistant", "second"
        add_message ctx, "user", "third"
        add_message ctx, "assistant", "fourth"
        add_message ctx, "user", "fifth"
      end

      it "emits compaction lifecycle callbacks" do
        compactor.call(keep: 3)
        expect(stream.events).must_equal [[:start, compactor], [:finish, compactor]]
      end
    end

    context "default keep value" do
      before { 70.times { |i| add_message ctx, "user", "message #{i}" } }

      it "keeps the default number of messages" do
        result = compactor.call
        expect(result.size).must_equal 64
        expect(result.last.content).must_equal "message 69"
      end

      it "returns nil when under the threshold" do
        ctx.messages.replace(ctx.messages.to_a.take(50))
        expect(compactor.call).must_be_nil
      end
    end
  end

  describe "context wiring" do
    it "keeps a configured compactor class" do
      compactor_class = Class.new(LLM::Compactor) { def call(**opts) = nil }
      expect(LLM::Context.new(provider, compactor: compactor_class).compactor).must_equal compactor_class
    end

    it "passes compactor_options to call" do
      keep = nil
      compactor_class = Class.new(LLM::Compactor) do
        define_method(:call) do |**opts|
          keep = opts[:keep]
          nil
        end
      end
      ctx = LLM::Context.new(provider, compactor: compactor_class, compactor_options: {keep: 5})
      ctx.compactor.new(ctx).call(**ctx.instance_variable_get(:@compactor)[:options])
      expect(keep).must_equal 5
    end

    it "calls the compactor before sending a request" do
      called = false
      compactor_class = Class.new(LLM::Compactor) do
        define_method(:call) do |**opts|
          called = true
          nil
        end
      end
      ctx = LLM::Context.new(provider, model: "gpt-4.1", compactor: compactor_class)
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
      ctx.talk("hello")
      expect(called).must_equal true
      expect(ctx.messages.last.content).must_equal "Hello from fixture"
    end

    it "does not mutate the caller's params hash" do
      compactor_class = Class.new(LLM::Compactor) { def call(**opts) = nil }
      params = {model: "gpt-4.1", compactor: compactor_class, compactor_options: {keep: 3}}
      LLM::Context.new(provider, params)
      expect(params.key?(:compactor)).must_equal true
      expect(params.key?(:compactor_options)).must_equal true
    end
  end

  describe "when given an agent" do
    it "unwraps the agent context" do
      agent = LLM::Agent.new(provider, model: "gpt-4.1")
      expect(LLM::Compactor::Null.new(agent).ctx).must_equal agent.instance_variable_get(:@ctx)
    end
  end
end

Minitest.run(ARGV) || exit(1)
