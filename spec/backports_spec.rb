# frozen_string_literal: true

describe "Phase J backports" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:tmpdir) { File.join(File.dirname(__FILE__), "tmp") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }

  describe "LLM::Tool.set" do
    let(:tool) do
      Class.new(LLM::Tool) do
        set name: "my-tool",
            description: "my tool does this and that",
            parameters: [
              [:name, String, "this and that"],
              [:age, Integer, "this and that"]
            ],
            required: %i[name],
            defaults: {age: 42}
      end
    end

    it "sets the tool name" do
      expect(tool.name).must_equal "my-tool"
    end

    it "sets the tool description" do
      expect(tool.description).must_equal "my tool does this and that"
    end

    it "defines the parameters" do
      expect(tool.function.params.properties[:name]).must_be_instance_of LLM::Schema::String
      expect(tool.function.params.properties[:age]).must_be_instance_of LLM::Schema::Integer
    end

    it "applies parameter defaults" do
      expect(tool.function.params.properties[:age].to_h[:default]).must_equal 42
    end

    it "marks parameters as required" do
      expect(tool.function.params.to_h[:required]).must_include :name
    end

    it "raises KeyError for unknown keys" do
      expect(proc { Class.new(LLM::Tool) { set bogus: 1 } }).must_raise KeyError
    end
  end

  describe "LLM::Tool::Param#defaults" do
    let(:tool) do
      Class.new(LLM::Tool) do
        name "greeter"
        description "Greets the user"
        parameter :name, String, "The user's name"
        parameter :count, Integer, "How many times"
        defaults name: "world", count: 3
      end
    end

    it "sets defaults for existing parameters" do
      expect(tool.function.params.properties[:name].to_h[:default]).must_equal "world"
      expect(tool.function.params.properties[:count].to_h[:default]).must_equal 3
    end
  end

  describe "LLM::Agent.set" do
    let(:agent_class) do
      Class.new(LLM::Agent) do
        set name: "admin",
            description: "system administrator",
            instructions: "You are an administrator",
            model: "gpt-4.1"
      end
    end

    it "sets the agent name" do
      expect(agent_class.name).must_equal "admin"
    end

    it "sets the agent description" do
      expect(agent_class.description).must_equal "system administrator"
    end

    it "applies class-level defaults to instances" do
      agent = agent_class.new(llm)
      expect(agent.name).must_equal "admin"
      expect(agent.description).must_equal "system administrator"
      expect(agent.model).must_equal "gpt-4.1"
    end

    it "raises KeyError for unknown keys" do
      expect(proc { Class.new(LLM::Agent) { set bogus: 1 } }).must_raise KeyError
    end
  end

  describe "LLM::Agent name DSL" do
    let(:agent_class) do
      Class.new(LLM::Agent) do
        def self.to_s
          "SystemAdmin"
        end
      end
    end

    it "derives a kebab-case name from the class name" do
      expect(agent_class.name).must_equal "system-admin"
    end
  end

  describe "LLM::Agent path persistence" do
    let(:memory_path) { File.join(tmpdir, "agent_memory.json") }
    let(:agent_class) do
      p = memory_path
      Class.new(LLM::Agent) do
        path p
      end
    end

    before do
      File.open(memory_path, "w") { |f| f.write(LLM.json.dump({
        schema_version: 1,
        model: "gpt-4.1",
        compacted: false,
        messages: [{role: "user", content: "hello"}]
      })) }
    end

    after do
      File.delete(memory_path) if File.exist?(memory_path)
    end

    it "restores context from the path on init" do
      agent = agent_class.new(llm)
      expect(agent.messages.map(&:content)).must_equal ["hello"]
    end

    it "saves the context after a turn" do
      transport.stub(
        "POST", "/v1/chat/completions",
        fixture: "openai/chat_completions.sse",
        headers: {"content-type" => "text/event-stream"}
      )
      agent = agent_class.new(llm, model: "gpt-4.1", stream: StringIO.new)
      agent.talk("Say hello")
      saved = LLM.json.load(File.read(memory_path))
      expect(saved["messages"].size > 0).must_equal true
    end
  end

  describe "LLM::Tracer::PrettyLogger" do
    let(:io) { StringIO.new }
    let(:tracer) { LLM::Tracer::PrettyLogger.new(llm, io: io) }

    it "writes a request start line" do
      tracer.on_request_start(operation: "chat", model: "gpt-4.1")
      expect(io.string).must_match(/openai chat \(gpt-4\.1\)/)
    end

    it "writes a request finish line with usage" do
      res = Object.new
      def res.usage
        LLM::Object.from(input_tokens: 10, output_tokens: 20)
      end
      tracer.on_request_start(operation: "chat", model: "gpt-4.1")
      tracer.on_request_finish(operation: "chat", res: res, model: "gpt-4.1")
      expect(io.string).must_match(/done, in=10 out=20/)
    end

    it "writes a tool start line" do
      tracer.on_tool_start(id: "call_1", name: "echo", arguments: {text: "hi"}, model: "gpt-4.1")
      expect(io.string).must_match(/echo\(text: "hi"\)/)
    end

    it "writes a tool finish line" do
      result = LLM::Function::Return.new("call_1", "echo", {ok: true})
      tracer.on_tool_finish(result: result)
      expect(io.string).must_match(/echo -> \{\.\.\.\}/)
    end

    it "writes a request error line" do
      tracer.on_request_error(ex: LLM::Error.new("boom"))
      expect(io.string).must_match(/openai error LLM::Error: boom/)
    end
  end

  describe "LLM::Tool::Ls" do
    let(:dir) { File.join(tmpdir, "ls_test") }

    before do
      Dir.mkdir(dir)
      File.open(File.join(dir, "a.rb"), "w") { |f| f.write("") }
      File.open(File.join(dir, "b.txt"), "w") { |f| f.write("") }
      Dir.mkdir(File.join(dir, "nested"))
      File.open(File.join(dir, "nested", "c.md"), "w") { |f| f.write("") }
    end

    after do
      File.delete(File.join(dir, "nested", "c.md"))
      Dir.delete(File.join(dir, "nested"))
      File.delete(File.join(dir, "a.rb"))
      File.delete(File.join(dir, "b.txt"))
      Dir.delete(dir)
    end

    it "lists directory entries" do
      result = LLM::Tool::Ls.new.call(path: dir)
      expect(result[:ok]).must_equal true
      expect(result[:count]).must_equal 3
    end

    it "filters entries with a glob" do
      result = LLM::Tool::Ls.new.call(path: dir, glob: "*.rb")
      expect(result[:entries]).must_equal [File.join(dir, "a.rb")]
    end

    it "supports recursive globs" do
      result = LLM::Tool::Ls.new.call(path: dir, glob: "**/*.md")
      expect(result[:entries]).must_equal [File.join(dir, "nested", "c.md")]
    end

    it "raises for a missing path" do
      expect(proc { LLM::Tool::Ls.new.call(path: File.join(dir, "missing")) }).must_raise RuntimeError
    end
  end

  describe "LLM::Tool::Which" do
    it "locates a command on the PATH" do
      result = LLM::Tool::Which.new.call(name: "sh")
      expect(result[:ok]).must_equal true
      expect(result[:path]).must_be_instance_of String
    end

    it "returns ok: false for a missing command" do
      result = LLM::Tool::Which.new.call(name: "no-such-command-xyz")
      expect(result[:ok]).must_equal false
      expect(result[:path]).must_be_nil
    end
  end

  describe "LLM::Tool::EditFile" do
    let(:path) { File.join(tmpdir, "edit.txt") }

    before do
      File.open(path, "w") { |f| f.write("foo bar baz") }
    end

    after do
      File.delete(path) if File.exist?(path)
    end

    it "replaces an exact snippet" do
      result = LLM::Tool::EditFile.new.call(path: path, before: "bar", after: "qux")
      expect(result[:ok]).must_equal true
      expect(result[:replaced]).must_equal 1
      expect(File.read(path)).must_equal "foo qux baz"
    end

    it "raises when the match count differs" do
      expect(proc {
        LLM::Tool::EditFile.new.call(path: path, before: "missing", after: "x")
      }).must_raise RuntimeError
    end
  end

  describe "LLM::Skill file-path loading" do
    before do
      Class.new(LLM::Tool) do
        name "frontmatter-read-file"
      end
    end

    it "loads a skill from a SKILL.md file path" do
      skill = LLM::Skill.load(File.join(root, "skills", "frontmatter-skill", "SKILL.md"))
      expect(skill.name).must_equal "frontmatter-skill"
      expect(skill.instructions).must_equal "Use frontmatter.\n"
    end

    it "loads all registered tools for tools: all" do
      skill = LLM::Skill.load(File.join(root, "skills", "all-tools-skill"))
      expect(skill.tools).must_equal LLM::Tool.registry
    end
  end

  describe "LLM::Buffer array methods" do
    let(:buffer) { LLM::Buffer.new(llm) }

    before do
      buffer << LLM::Message.new(:user, "one")
      buffer << LLM::Message.new(:user, "two")
      buffer << LLM::Message.new(:user, "three")
    end

    it "returns the first message" do
      expect(buffer.first.content).must_equal "one"
    end

    it "returns the first n messages" do
      expect(buffer.first(2).map(&:content)).must_equal %w[one two]
    end

    it "drops messages" do
      expect(buffer.drop(2).map(&:content)).must_equal ["three"]
    end

    it "takes messages" do
      expect(buffer.take(2).map(&:content)).must_equal %w[one two]
    end

    it "rejects messages in place" do
      buffer.reject! { |m| m.content == "two" }
      expect(buffer.map(&:content)).must_equal %w[one three]
    end

    it "aliases delete_if to reject!" do
      buffer.delete_if { |m| m.content == "one" }
      expect(buffer.map(&:content)).must_equal %w[two three]
    end

    it "selects messages in place" do
      buffer.select! { |m| m.content == "three" }
      expect(buffer.map(&:content)).must_equal ["three"]
    end

    it "shifts the first message" do
      expect(buffer.shift.content).must_equal "one"
      expect(buffer.size).must_equal 2
    end

    it "clears the buffer" do
      buffer.clear
      expect(buffer.empty?).must_equal true
    end

    it "pops the last message" do
      expect(buffer.pop.content).must_equal "three"
      expect(buffer.size).must_equal 2
    end

    it "reverses the buffer" do
      expect(buffer.reverse.map(&:content)).must_equal %w[three two one]
    end
  end

  describe "LLM::Schema::Leaf#index" do
    it "stamps property definition order" do
      schema = Class.new(LLM::Schema) do
        property :name, String, "name"
        property :age, Integer, "age"
      end
      expect(schema.object.properties["name"].index).must_equal 0
      expect(schema.object.properties["age"].index).must_equal 1
    end
  end

  describe "LLM::Object#fetch" do
    it "raises KeyError with the original key name" do
      obj = LLM::Object.from(foo: 1)
      err = begin
        obj.fetch(:missing)
        nil
      rescue => e
        e
      end
      expect(err).must_be_instance_of KeyError
      expect(err.message).must_include "missing"
    end
  end

  describe "LLM::NotFoundError" do
    it "is raised for 404 responses" do
      res = LLM::Transport::Response.new(404, {}, "not found")
      handler = LLM::OpenAI::ErrorHandler.new(LLM::Tracer::Null.new(llm), nil, res)
      expect(proc { handler.raise_error! }).must_raise LLM::NotFoundError
    end
  end

  describe "LLM::Function#def" do
    it "aliases def to define" do
      fn = LLM.function(:echo) do |f|
        f.name "echo"
        f.def do
          {ok: true}
        end
      end
      expect(fn.call.value).must_equal({ok: true})
    end
  end

  describe "LLM::File#exist?" do
    it "returns whether the file exists" do
      expect(LLM::File.new(__FILE__).exist?).must_equal true
      expect(LLM::File.new(File.join(tmpdir, "no-such-file")).exist?).must_equal false
    end
  end

  describe "LLM::MCP#session" do
    it "aliases session to run" do
      mcp = LLM::MCP.stdio(argv: ["echo"])
      expect(mcp).must_respond_to :session
    end
  end

  describe "LLM::Function#budget_spent" do
    let(:fn) do
      LLM.function(:echo) do |f|
        f.name "echo"
      end.tap { _1.id = "call_1" }
    end

    it "returns an in-band budget spent error" do
      result = fn.budget_spent
      expect(result).must_be_instance_of LLM::Function::Return
      expect(result.value[:error]).must_equal true
      expect(result.value[:type]).must_equal "LLM::BudgetSpentError"
      expect(result.value[:message]).must_include "budget"
    end
  end

  describe "LLM::Agent.tool_budget" do
    it "defaults to nil (disabled)" do
      expect(LLM::Agent.tool_budget).must_be_nil
    end

    it "is settable as a class DSL" do
      agent_class = Class.new(LLM::Agent) { tool_budget 5 }
      expect(agent_class.tool_budget).must_equal 5
    end

    it "applies the class budget to agent instances" do
      agent_class = Class.new(LLM::Agent) { tool_budget 5 }
      agent = agent_class.new(llm)
      expect(agent.instance_variable_get(:@tool_budget)).must_equal 5
    end
  end

  describe "LLM::Agent#compacted?" do
    it "reflects the wrapped context's compaction state" do
      agent = LLM::Agent.new(llm)
      expect(agent.compacted?).must_be_nil
      agent.instance_variable_get(:@ctx).compacted = true
      expect(agent.compacted?).must_equal true
    end
  end

  describe "OpenAI subclass host forwarding" do
    it "forwards host: to the provider base for OpenAI subclasses" do
      transport = LLM::Test::Transport.new(root: root)
      {
        LLM::DeepInfra => "api.deepinfra.com",
        LLM::Mistral => "api.mistral.ai",
        LLM::Moonshot => "api.moonshot.ai"
      }.each do |klass, host|
        provider = klass.new(key: "test-key", transport: transport)
        expect(provider.instance_variable_get(:@host)).must_equal host
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
