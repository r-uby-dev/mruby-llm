# frozen_string_literal: true

module LLM::URI
  ##
  # {LLM::URI::Parsed LLM::URI::Parsed} is a small parsed URI object
  # for the mruby port.
  #
  # It only implements the subset of URI state currently needed by the
  # transport layer.
  class Parsed
    ABSOLUTE_PATTERN = %r{
      \A
      (?<scheme>[a-z][a-z0-9+\-.]*)
      ://
      (?<host>[A-Za-z0-9.\-]+)
      (?::(?<port>\d+))?
      (?<request_uri>
        /[^\?#]*(?:\?[^\#]*)?
        |
        \?[^\#]*
      )?
      (?:\#.*)?
      \z
    }x
    RELATIVE_PATTERN = %r{
      \A
      (?<path>[^\#]*)
      (?:\#.*)?
      \z
    }x

    ##
    # @return [String, nil]
    attr_reader :scheme

    ##
    # @return [String, nil]
    attr_reader :host

    ##
    # @return [Integer, nil]
    attr_reader :port

    ##
    # @return [String]
    attr_reader :request_uri

    ##
    # @param [#to_s] value
    # @return [LLM::URI::Parsed]
    def initialize(value)
      @value = value.to_s
      if match = ABSOLUTE_PATTERN.match(@value)
        @scheme = match[:scheme]
        @host = match[:host]
        @port = match[:port] ? match[:port].to_i : default_port(@scheme)
        request_uri = match[:request_uri].to_s
        @request_uri = if request_uri.empty?
          "/"
        elsif request_uri.start_with?("?")
          "/#{request_uri}"
        else
          request_uri
        end
      else
        match = RELATIVE_PATTERN.match(@value)
        @scheme = nil
        @host = nil
        @port = nil
        @request_uri = match[:path].to_s.empty? ? "/" : match[:path]
      end
    end

    ##
    # @return [String]
    def to_s
      @value
    end

    private

    def default_port(scheme)
      case scheme
      when "https" then 443
      when "http" then 80
      end
    end
  end
end
