# frozen_string_literal: true

describe "LLM::URI.parse" do
  context "when given an http URL with an explicit port" do
    let(:uri) { LLM::URI.parse("http://localhost:9999") }

    it "parses the host" do
      expect(uri.host).must_equal "localhost"
    end

    it "parses the port" do
      expect(uri.port).must_equal 9999
    end

    it "defaults the request URI to the root path" do
      expect(uri.request_uri).must_equal "/"
    end
  end

  context "when given an https URL with a path and query" do
    let(:uri) { LLM::URI.parse("https://example.com/v1/models?limit=10") }

    it "parses the scheme" do
      expect(uri.scheme).must_equal "https"
    end

    it "uses the default https port" do
      expect(uri.port).must_equal 443
    end

    it "preserves the request URI" do
      expect(uri.request_uri).must_equal "/v1/models?limit=10"
    end
  end

  context "when given an https URL with a path and no query" do
    let(:uri) { LLM::URI.parse("https://example.com/v1/models") }

    it "preserves the path as the request URI" do
      expect(uri.request_uri).must_equal "/v1/models"
    end
  end

  context "when given an http URL with a port and path" do
    let(:uri) { LLM::URI.parse("http://localhost:9999/v1/models") }

    it "preserves the port-qualified path as the request URI" do
      expect(uri.request_uri).must_equal "/v1/models"
    end
  end

  context "when given a URL with a fragment" do
    let(:uri) { LLM::URI.parse("https://example.com/tasks/1?historyLength=5#ignored") }

    it "drops the fragment from the request URI" do
      expect(uri.request_uri).must_equal "/tasks/1?historyLength=5"
    end
  end

  context "when given a relative path" do
    let(:uri) { LLM::URI.parse("/v1/chat/completions") }

    it "leaves the path as the request URI" do
      expect(uri.request_uri).must_equal "/v1/chat/completions"
    end

    it "does not infer a host" do
      expect(uri.host).must_be_nil
    end
  end
end
