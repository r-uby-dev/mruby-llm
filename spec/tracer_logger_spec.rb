# frozen_string_literal: true

describe "LLM::Tracer::Logger" do
  let(:io) { StringIO.new }
  let(:llm) { LLM.openai(key: "test-key") }
  let(:tracer) { LLM::Tracer::Logger.new(llm, io:) }
  let(:events) { io.string.lines.map { LLM.json.load(_1) } }

  describe "#on_request_start" do
    before do
      tracer.on_request_start(operation: "chat", model: "gpt-4.1")
    end

    it "writes a request start event" do
      expect(events.first["event"]).must_equal "request.start"
    end

    it "writes the model" do
      expect(events.first["model"]).must_equal "gpt-4.1"
    end
  end

  describe "#on_tool_finish" do
    let(:result) { LLM::Function::Return.new("call_1", "system", {ok: true}) }

    before do
      tracer.on_tool_finish(result:)
    end

    it "writes a tool finish event" do
      expect(events.first["event"]).must_equal "tool.finish"
    end

    it "writes the tool result" do
      expect(events.first["tool_result"]).must_equal({"ok" => true})
    end
  end

  describe "traced function calls" do
    let(:function) do
      LLM.function(:system) do |fn|
        fn.name "system"
        fn.define do
          {ok: true}
        end
      end
    end

    before do
      function.id = "call_1"
      function.tracer = tracer
      function.call
    end

    it "writes a tool start event" do
      expect(events.first["event"]).must_equal "tool.start"
    end

    it "writes a tool finish event" do
      expect(events.last["event"]).must_equal "tool.finish"
    end
  end
end

Minitest.run(ARGV) || exit(1)
