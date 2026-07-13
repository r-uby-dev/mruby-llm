# frozen_string_literal: true

class LLM::Stream
  ##
  # An {LLM::Stream::Disabled LLM::Stream::Disabled} represents a stream
  # that is explicitly turned off.
  #
  # {LLM::Stream.try} returns an instance of this class when given `false`
  # or `nil`. Providers check {#enabled?} to decide whether to request a
  # streaming response from the API. When disabled, the stream is replaced
  # with `nil` before the transport layer executes the request.
  #
  # All callback methods inherited from {LLM::Stream LLM::Stream} are no-ops,
  # so a disabled stream can be used safely wherever a stream object is
  # expected.
  class Disabled < self
    ##
    # @return [false]
    def enabled?
      false
    end
  end
end
