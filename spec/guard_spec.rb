# frozen_string_literal: true

describe "LLM::Guard" do
  let(:provider) { LLM.openai(key: "test-key") }
  let(:ctx) { LLM::Context.new(provider) }
  let(:tool_class) do
    Class.new(LLM::Tool) do
      name "echo"
      description "Echo a value"
      parameter :value, String, "Value", required: true
      def call(value:)
        {value: value}
      end
    end
  end
  let(:function) do
    tool_class.new.function.tap do |fn|
      fn.id = "call_1"
      fn.arguments = {"value" => "hello"}
    end
  end
  let(:blocking_guard) do
    Class.new(LLM::Guard) do
      def call(function:, **)
        LLM::Function::Return.new(function.id, function.name, {
          error: true, type: "guard_error", message: "stop"
        })
      end
    end
  end

  describe "LLM::Guard::Null" do
    it "never blocks" do
      expect(LLM::Guard::Null.new(ctx).call(function: function)).must_be_nil
    end

    it "is the default guard" do
      expect(ctx.guard).must_equal LLM::Guard::Null
    end
  end

  describe "LLM::Guard::Loop" do
    before do
      3.times do
        ctx.messages << LLM::Message.new("assistant", nil, {
          tools: [tool_class],
          tool_calls: [
            {id: "call_x", name: "echo", arguments: {"value" => "hello"}}
          ]
        })
      end
    end

    it "returns a guarded return on a repeated tool-call pattern" do
      result = LLM::Guard::Loop.new(ctx).call(function: function)
      expect(result).must_be_instance_of LLM::Function::Return
      expect(result.id).must_equal function.id
      expect(result.name).must_equal function.name
      expect(result.value[:error]).must_equal true
      expect(result.value[:type]).must_equal "guard_error"
      expect(result.value[:message]).must_include "Repeated tool-call pattern"
    end

    it "respects a custom threshold" do
      expect(LLM::Guard::Loop.new(ctx).call(function: function, threshold: 4)).must_be_nil
    end
  end

  describe "context wiring" do
    it "uses the loop guard when configured with a class" do
      expect(LLM::Context.new(provider, guard: LLM::Guard::Loop).guard).must_equal LLM::Guard::Loop
    end

    it "keeps a custom guard class" do
      guard = Class.new(LLM::Guard) do
        def call(function:, **)
          "stop"
        end
      end
      expect(LLM::Context.new(provider, guard: guard).guard).must_equal guard
    end

    it "passes guard_options to the guard" do
      threshold = nil
      guard = Class.new(LLM::Guard) do
        define_method(:call) do |function:, **opts|
          threshold = opts[:threshold]
          nil
        end
      end
      ctx = LLM::Context.new(provider, guard: guard, guard_options: {threshold: 5})
      ctx.guard.new(ctx).call(function: function, **ctx.instance_variable_get(:@guard)[:options])
      expect(threshold).must_equal 5
    end
  end

  describe "Function#return" do
    it "builds a return with the function's id and name" do
      result = function.return(error: true, type: "guard_error", message: "stop")
      expect(result.id).must_equal "call_1"
      expect(result.name).must_equal "echo"
      expect(result.value).must_equal(error: true, type: "guard_error", message: "stop")
    end
  end

  describe "guarded task short-circuit" do
    it "returns the guarded return without calling the tool" do
      function.guard = blocking_guard.new(ctx)
      result = function.task(:sequential).wait
      expect(result.value).must_equal(error: true, type: "guard_error", message: "stop")
    end

    it "short-circuits :task and :fork strategies" do
      function.guard = blocking_guard.new(ctx)
      [:task, :fork].each do |strategy|
        result = function.task(strategy).wait
        expect(result.value).must_equal(error: true, type: "guard_error", message: "stop")
      end
    end

    it "stamps the guard through ctx.pending_functions" do
      ctx = LLM::Context.new(provider, guard: blocking_guard)
      ctx.messages << LLM::Message.new("assistant", nil, {
        tools: [tool_class],
        tool_calls: [
          {id: "call_1", name: "echo", arguments: {"value" => "hello"}}
        ]
      })
      result = ctx.wait(:sequential).first
      expect(result.value).must_equal(error: true, type: "guard_error", message: "stop")
    end
  end
end

Minitest.run(ARGV) || exit(1)
