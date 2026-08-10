# frozen_string_literal: true

describe "LLM::Provider" do
  let(:provider_class) do
    Class.new(LLM::Provider) do
      def name
        :dummy
      end
      def complete(*)
        raise NotImplementedError
      end
      def embed(*)
        raise NotImplementedError
      end
    end
  end
  let(:transport) do
    Object.new.tap do |object|
      def object.inspect = "#<transport>"
      def object.request_owner = nil
      def object.interrupt!(*) = nil
    end
  end

  context "when the base path includes trailing slashes" do
    let(:provider) do
      provider_class.new(key: "test", host: "example.com", base_path: " /v1/// ", transport:)
    end

    it "normalizes the path without relying on String#sub" do
      expect(provider.send(:path, "/chat/completions")).must_equal "/v1/chat/completions"
    end
  end

  context "when the base path is the root path" do
    let(:provider) do
      provider_class.new(key: "test", host: "example.com", base_path: "/", transport:)
    end

    it "treats the base path as empty" do
      expect(provider.send(:path, "/chat/completions")).must_equal "/chat/completions"
    end
  end

  context "#key?" do
    it "returns false when the key is nil" do
      provider = provider_class.new(key: nil, host: "example.com", transport:)
      expect(provider.key?).must_equal false
    end

    it "returns false when the key is blank" do
      provider = provider_class.new(key: "   ", host: "example.com", transport:)
      expect(provider.key?).must_equal false
    end

    it "returns true when the key is set" do
      provider = provider_class.new(key: "sk-12345", host: "example.com", transport:)
      expect(provider.key?).must_equal true
    end
  end

  context "#build_messages" do
    let(:provider) { provider_class.new(key: "test", host: "example.com", transport:) }
    let(:history) { LLM::Message.new("user", "hi") }

    it "wraps a string prompt with the given role" do
      messages = provider.build_messages("hello", {}, :user)
      expect(messages.size).must_equal 1
      expect(messages[0]).must_be_instance_of LLM::Message
      expect(messages[0].role).must_equal "user"
      expect(messages[0].content).must_equal "hello"
    end

    it "prepends history from the params key" do
      params = {messages: [history]}
      messages = provider.build_messages("hello", params, :user)
      expect(messages.size).must_equal 2
      expect(messages[0]).must_equal history
      expect(messages[1].content).must_equal "hello"
      expect(params.key?(:messages)).must_equal false
    end

    it "is idempotent for message arrays" do
      messages = [LLM::Message.new("user", "a"), LLM::Message.new("assistant", "b")]
      expect(provider.build_messages(messages, {}, :user)).must_equal messages
    end

    it "is idempotent for a single message" do
      message = LLM::Message.new("user", "a")
      expect(provider.build_messages(message, {}, :user)).must_equal [message]
    end

    it "expands a prompt into its messages" do
      prompt = LLM::Prompt.new(provider) do
        _1.user "a"
        _1.system "b"
      end
      messages = provider.build_messages(prompt, {}, :user)
      expect(messages.size).must_equal 2
      expect(messages[0].role).must_equal "user"
      expect(messages[1].role).must_equal "system"
    end

    it "uses the key for responses-style input" do
      params = {input: [history]}
      messages = provider.build_messages("hello", params, :user, key: :input)
      expect(messages.size).must_equal 2
      expect(messages[0]).must_equal history
      expect(params.key?(:input)).must_equal false
    end

    it "wraps a mixed array as a single message" do
      messages = provider.build_messages([history, "tail"], {}, :user)
      expect(messages.size).must_equal 1
      expect(messages[0].content).must_equal [history, "tail"]
    end
  end
end

Minitest.run(ARGV) || exit(1)
