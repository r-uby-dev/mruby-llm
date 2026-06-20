# frozen_string_literal: true

describe "LLM::Transport::Curl" do
  let(:described_class) { LLM::Transport::Curl }
  let(:transport) { described_class.new(host: "api.openai.com", port: 443, timeout: 60, ssl: true) }
  let(:request) { LLM::Transport::Request.post("/v1/chat/completions", "content-type" => "application/json") }
  subject { transport.send(:build_http_request, request) }

  before do
    transport.set_body_stream(request, StringIO.new(%({"messages":[]})))
  end

  it "sends buffered body streams with a content length" do
    expect(subject.body).must_equal %({"messages":[]})
    expect(subject.headers["transfer-encoding"]).must_be_nil
    expect(subject.headers["content-length"]).must_equal "15"
  end
end

Minitest.run(ARGV) || exit(1)
