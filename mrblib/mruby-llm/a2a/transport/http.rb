# frozen_string_literal: true

class LLM::A2A
  module Transport
    ##
    # The {LLM::A2A::Transport::HTTP} class provides the HTTP+JSON/REST
    # protocol binding for the A2A protocol.
    class HTTP
      ##
      # @param [String] url The base URL of the A2A agent
      # @param [Hash<String, String>] headers Extra HTTP headers
      # @param [Integer, nil] timeout The timeout in seconds
      # @param [LLM::Transport, Class, nil] transport Override transport
      # @param [String] protocol_version The A2A protocol version header
      def initialize(url:, headers: {}, timeout: nil, transport: nil, protocol_version: "1.0")
        @uri = LLM::URI.parse(url)
        @headers = headers
        @protocol_version = protocol_version
        @transport = LLM::Utils.resolve_transport(@uri, transport, timeout)
      end

      ##
      # Sends a GET request.
      # @param [String] path The URL path
      # @return [Hash]
      def get(path, accept: "application/json")
        req = LLM::Transport::Request.get(request_path(path), headers(accept:))
        res = transport.request(req, owner: self)
        parse_response(res)
      end

      ##
      # Sends a POST request.
      # @param [String] path The URL path
      # @param [Hash] body The JSON body
      # @return [Hash]
      def post(path, body, content_type: "application/json", accept: "application/json")
        req = LLM::Transport::Request.post(request_path(path), headers(content_type:, accept:))
        req.body = LLM.json.dump(body)
        res = transport.request(req, owner: self)
        parse_response(res)
      end

      ##
      # Sends a DELETE request.
      # @param [String] path The URL path
      # @return [Hash]
      def delete(path, accept: "application/json")
        req = LLM::Transport::Request.delete(request_path(path), headers(accept:))
        res = transport.request(req, owner: self)
        parse_response(res)
      end

      ##
      # Sends a GET request with a streaming (SSE) response.
      #
      # The block is called for each event parsed from the event stream.
      # @param [String] path The URL path
      # @yieldparam [Hash] event A stream event
      # @return [void]
      def get_stream(path, &on_event)
        req = LLM::Transport::Request.get(request_path(path), headers(accept: "text/event-stream"))
        stream(req, &on_event)
      end

      ##
      # Sends a POST request with a streaming (SSE) response.
      #
      # The block is called for each event parsed from the event stream.
      # @param [String] path The URL path
      # @param [Hash] body The JSON body
      # @yieldparam [Hash] event A stream event
      # @return [void]
      def post_stream(path, body, content_type: "application/json", &on_event)
        req = LLM::Transport::Request.post(request_path(path), headers(content_type:, accept: "text/event-stream"))
        req.body = LLM.json.dump(body)
        stream(req, &on_event)
      end

      private

      attr_reader :transport

      def headers(content_type: "application/json", accept: "application/json")
        {
          "A2A-Version" => @protocol_version,
          "content-type" => content_type,
          "accept" => accept
        }.merge(@headers)
      end

      def request_path(path)
        path = LLM::Utils.normalize_base_path(path)
        path.empty? ? "/" : path
      end

      def stream(req, &on_event)
        transport.request(req, owner: self) do |raw|
          raw = LLM::Transport::Response.from(raw)
          next raw unless raw.success?
          decoder = LLM::Transport::StreamDecoder.new { on_event&.call(_1) }
          raw.read_body { decoder << _1 }
          decoder.free
        end
      end

      def parse_response(res)
        res = LLM::Transport::Response.from(res)
        body = +""
        res.read_body { body << _1 }
        if res.success?
          body.empty? ? {} : LLM.json.load(body)
        else
          handle_error(res.code, body)
        end
      end

      def handle_error(code, body)
        data = LLM.json.load(body) rescue {}
        msg = data.dig("error", "message") || data["message"] || "HTTP #{code}"
        raise LLM::A2A::Error.new(msg, code.to_i, data)
      end
    end
  end
end
