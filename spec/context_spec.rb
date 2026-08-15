# frozen_string_literal: true

describe "LLM::Context" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:provider) { LLM.openai(key: "test-key", transport:) }
  let(:params) { {} }
  let(:ctx) { LLM::Context.new(provider, params) }
  let(:path) { File.join(File.dirname(__FILE__), "tmp", "context.json") }

  context "when given a thread of messages" do
    let(:params) { {model: "gpt-4.1"} }
    let(:messages) { ctx.messages }
    let(:msg) { messages.to_a[-1] }
    let(:system_prompt) { "Keep your answers short and concise" }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk system_prompt
        _1.talk "Say hello"
      end
    end

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
      ctx.talk(prompt)
    end

    it "provides a response" do
      expect(msg.role).must_equal "assistant"
      expect(msg.content).must_equal "Hello from fixture"
    end

    it "provides an Enumerator" do
      expect(messages.each).must_be_instance_of Enumerator
    end

    it "provides a message at an index" do
      0.upto(2) { |i| expect(messages[i]).must_be_instance_of LLM::Message }
    end

    it "returns nil when an index is out of bounds" do
      expect(messages[3]).must_be_nil
    end

    it "provides the last message" do
      expect(messages.last).must_equal messages.to_a[-1]
    end
  end

  context "when given an IO stream" do
    let(:stream) { StringIO.new }
    let(:params) { {model: "gpt-4.1", stream:} }
    let(:system_prompt) { "Keep your answers short and concise" }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk system_prompt
        _1.talk "Say hello there"
      end
    end

    before do
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions.sse",
        headers: {"content-type" => "text/event-stream"}
      )
      ctx.talk(prompt)
    end

    it "streams text into the IO" do
      expect(stream.string).must_equal "Hello there"
    end

    it "stores the streamed assistant message" do
      expect(ctx.messages.find(&:assistant?).content).must_equal "Hello there"
    end

    it "stores usage on the assistant message" do
      usage = ctx.messages.find(&:assistant?)&.usage
      expect(usage.input_tokens).must_equal 4
      expect(usage.output_tokens).must_equal 2
      expect(usage.total_tokens).must_equal 6
    end
  end

  context "when given a tool call" do
    let(:tool) do
      Class.new(LLM::Tool) do
        name "system"
        description "Runs system commands"
        parameter :command, String, "The command to run"
        required %i[command]

        def call(command:)
          {"success" => command == "date" ? "2025-08-24" : false}
        end
      end
    end
    let(:params) { {model: "gpt-4.1", tools: [tool]} }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk "You are a bot that can run UNIX system commands"
        _1.talk "Hey, run the 'date' command"
      end
    end

    before do
      transport
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool.json")
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_tool_result.json")
      ctx.talk(prompt)
    end

    it "exposes pending functions" do
      expect(ctx.pending_functions.empty?).must_equal false
      expect(ctx.pending_functions?).must_equal true
    end

    it "calls the function" do
      ctx.talk ctx.pending_functions[0].call
      expect(ctx.pending_functions).must_be_empty
      expect(ctx.pending_functions?).must_equal false
    end

    it "calls the functions" do
      ctx.talk ctx.pending_functions.map(&:call)
      expect(ctx.pending_functions).must_be_empty
    end

    it "waits for functions through :sequential" do
      ctx.talk ctx.wait(:sequential)
      expect(ctx.pending_functions).must_be_empty
    end

    it "includes a message with a return value" do
      ctx.talk ctx.pending_functions.map(&:call)
      expect(ctx.messages.select(&:tool_return?).size).must_equal 1
    end

    it "returns the final assistant answer after the tool loop" do
      res = ctx.talk ctx.pending_functions.map(&:call)
      expect(res.content).must_equal "Today's date is August 24, 2025."
      expect(ctx.messages.last.content).must_equal "Today's date is August 24, 2025."
    end
  end

  context "when given a streamed tool call" do
    let(:stream) do
      Class.new(LLM::Stream) do
        attr_reader :returns
        def initialize
          @returns = []
        end
        def on_tool_return(tool, result)
          @returns << [tool.name, result.name, result.value]
        end
      end.new
    end
    let(:tool) do
      Class.new(LLM::Tool) do
        name "system"
        description "Runs system commands"
        parameter :command, String, "The command to run"
        required %i[command]

        def call(command:)
          {"success" => command == "date" ? "2025-08-24" : false}
        end
      end
    end
    let(:params) { {model: "gpt-4.1", stream:, tools: [tool]} }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk "You are a bot that can run UNIX system commands"
        _1.talk "Hey, run the 'date' command"
      end
    end

    before do
      transport
        .stub(
          "POST", "/v1/chat/completions",
          fixture: "openai/chat_completions_tool.sse",
          headers: {"content-type" => "text/event-stream"}
        )
        .stub(
          "POST", "/v1/chat/completions",
          fixture: "openai/chat_completions_tool_result.sse",
          headers: {"content-type" => "text/event-stream"}
        )
      ctx.talk(prompt)
    end

    it "calls the function(s)" do
      res = ctx.talk ctx.pending_functions.map(&:call)
      expect(ctx.pending_functions).must_be_empty
      expect(res.content).must_equal "Today's date is August 24, 2025."
      expect(ctx.messages.last.content).must_equal "Today's date is August 24, 2025."
    end

    it "emits tool returns from direct waits" do
      ctx.wait(:sequential)
      expect(stream.returns).must_equal [["system", "system", {"success" => "2025-08-24"}]]
    end
  end

  context "when resuming a serialized conversation" do
    let(:params) { {model: "gpt-4.1"} }
    let(:prompt) do
      ctx.build_prompt do
        _1.talk "Keep your answers short and concise"
        _1.talk "Say hello"
      end
    end
    let(:restored) { LLM::Context.new(provider, params) }
    let(:resumed_prompt) do
      restored.build_prompt do
        _1.talk "What did we just say?"
      end
    end

    before do
      transport
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions.json")
        .stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_resume.json")
      ctx.talk(prompt)
      ctx.serialize(path:)
      restored.restore(path:)
    end

    after do
      File.delete(path) if File.exist?(path)
    end

    it "restores the message history" do
      expect(restored.messages.size).must_equal 3
      expect(restored.messages[0].role).must_equal "user"
      expect(restored.messages[1].role).must_equal "user"
      expect(restored.messages[2].content).must_equal "Hello from fixture"
    end

    it "continues the conversation after restore" do
      res = restored.talk(resumed_prompt)
      expect(res.content).must_equal "You just said hello, and I answered Hello from fixture."
      expect(restored.messages.last.content).must_equal "You just said hello, and I answered Hello from fixture."
    end
  end

  context "when a request is rate limited" do
    ##
    # The mruby specs have no general method-stub helper, so sleep is
    # neutralized on the context to keep the suite fast.
    class LLM::Context
      def sleep(*)
        nil
      end
    end

    describe "retry budget" do
      it "defaults to 0" do
        expect(LLM::Context.new(provider).retry_budget).must_equal 0
      end

      it "returns the configured budget" do
        expect(LLM::Context.new(provider, retry_budget: 5).retry_budget).must_equal 5
      end
    end

    context "when a request is rate limited then succeeds" do
      let(:stream) do
        Class.new(LLM::Stream) do
          attr_reader :limits
          def initialize
            @limits = []
          end
          def on_rate_limit(error)
            @limits << error
          end
        end.new
      end
      let(:params) { {model: "gpt-4.1", retry_budget: 3, stream:} }
      let(:ctx) { LLM::Context.new(provider, params) }

      before do
        transport
          .stub("POST", "/v1/chat/completions", fixture: "openai/rate_limited.json", code: 429)
          .stub(
            "POST", "/v1/chat/completions",
            fixture: "openai/chat_completions.sse",
            headers: {"content-type" => "text/event-stream"}
          )
        ctx.talk("ping")
      end

      it "retries and succeeds" do
        expect(ctx.messages.find(&:assistant?).content).must_equal "Hello there"
      end

      it "notifies the stream once per rate limit" do
        expect(stream.limits.size).must_equal 1
      end

      it "notifies the stream with rate limit errors" do
        expect(stream.limits[0]).must_be_instance_of LLM::RateLimitError
      end
    end

    context "when the budget is exhausted" do
      let(:ctx) { LLM::Context.new(provider, model: "gpt-4.1", retry_budget: 2) }

      before do
        3.times do
          transport.stub("POST", "/v1/chat/completions", fixture: "openai/rate_limited.json", code: 429)
        end
      end

      it "re-raises the rate limit error" do
        expect { ctx.talk("ping") }.must_raise LLM::RateLimitError
      end
    end
  end

  context "#token_usage" do
    it "returns LLM::Usage.zero before any turn" do
      usage = ctx.token_usage
      expect(usage).must_be_instance_of LLM::Usage
      expect(usage.input_tokens).must_equal 0
      expect(usage.output_tokens).must_equal 0
      expect(usage.reasoning_tokens).must_equal 0
      expect(usage.total_tokens).must_equal 0
    end

    it "aliases usage to token_usage" do
      expect(ctx.usage).must_equal ctx.token_usage
    end

    it "zero-fills missing token fields" do
      ctx.messages << LLM::Message.new("assistant", "hello", usage: LLM::Object.from(input_tokens: 3))
      usage = ctx.token_usage
      expect(usage).must_be_instance_of LLM::Usage
      expect(usage.input_tokens).must_equal 3
      expect(usage.output_tokens).must_equal 0
      expect(usage.reasoning_tokens).must_equal 0
      expect(usage.cache_read_tokens).must_equal 0
      expect(usage.cache_write_tokens).must_equal 0
      expect(usage.total_tokens).must_equal 0
    end

    it "sums usage across all assistant messages" do
      ctx.messages << LLM::Message.new("user", "hi")
      ctx.messages << LLM::Message.new(
        "assistant", "one",
        usage: LLM::Object.from(input_tokens: 3, output_tokens: 2, total_tokens: 5)
      )
      ctx.messages << LLM::Message.new("user", "again")
      ctx.messages << LLM::Message.new(
        "assistant", "two",
        usage: LLM::Object.from(input_tokens: 7, output_tokens: 1, total_tokens: 8)
      )
      usage = ctx.token_usage
      expect(usage.input_tokens).must_equal 10
      expect(usage.output_tokens).must_equal 3
      expect(usage.total_tokens).must_equal 13
    end
  end

  context "#context_used" do
    it "returns nil before any turn" do
      expect(ctx.context_used).must_be_nil
    end

    it "returns the total tokens of the most recent assistant message" do
      ctx.messages << LLM::Message.new("user", "hi")
      ctx.messages << LLM::Message.new("assistant", "hello", usage: LLM::Object.from(total_tokens: 123))
      expect(ctx.context_used).must_equal 123
    end
  end

  context "#context_usage" do
    it "returns nil when the conversation is too short" do
      ctx.messages << LLM::Message.new("assistant", "hello", usage: LLM::Object.from(total_tokens: 123))
      expect(ctx.context_usage).must_be_nil
    end

    it "returns the fraction of the context window used" do
      ctx.messages << LLM::Message.new("user", "hi")
      ctx.messages << LLM::Message.new("assistant", "hello", usage: LLM::Object.from(total_tokens: 500))
      expect(ctx.context_usage).must_equal Rational(500, ctx.context_window)
    end

    it "returns nil when the model is not in the registry" do
      other = LLM::Context.new(provider, model: "no-such-model-xyz")
      other.messages << LLM::Message.new("user", "hi")
      other.messages << LLM::Message.new("assistant", "hello", usage: LLM::Object.from(total_tokens: 500))
      expect(other.context_usage).must_be_nil
    end
  end

  context "#context_window" do
    it "returns the model's context window" do
      expect(LLM::Context.new(provider, model: "gpt-4.1").context_window).must_equal 1_047_576
    end

    it "returns nil when the model is not in the registry" do
      expect(LLM::Context.new(provider, model: "no-such-model-xyz").context_window).must_be_nil
    end
  end

  context "#registry" do
    it "delegates to the provider's registry" do
      expect(ctx.registry).must_equal provider.registry
      expect(ctx.registry).must_be_instance_of LLM::Registry
      expect(ctx.registry.keys).must_include "gpt-4.1"
    end
  end
end

Minitest.run(ARGV) || exit(1)
