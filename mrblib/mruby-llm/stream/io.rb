# frozen_string_literal: true

class LLM::Stream
  ##
  # An {LLM::Stream::IO LLM::Stream::IO} wraps an object that responds to
  # `#<<` or `#write` and forwards streamed content to it.
  #
  # This enables any object that implements `#<<` - such as an IO, StringIO,
  # or a custom logger - to be used as a stream target. {LLM::Stream.try}
  # creates instances of this class automatically when given an IO-like
  # object. On mruby, `StringIO` only implements `#write`, so content is
  # forwarded through `#write` when `#<<` is unavailable.
  #
  # @example Using an IO object as a stream
  #   File.open("output.txt", "w") do |file|
  #     ctx.ask("Tell me a story", stream: file)
  #   end
  class IO < self
    ##
    # @param [#<<, #write] io
    #  Any object that implements `#<<` or `#write`.
    def initialize(io)
      @io = io
    end

    ##
    # Writes a chunk of content to the wrapped IO object.
    # @param [String] content
    # @return [void]
    def on_content(content)
      if @io.respond_to?(:<<)
        @io << content
      else
        @io.write(content)
      end
    end

    ##
    # Forwards streamed content to the wrapped IO object.
    # Redefined here because +alias_method+ in the parent class
    # captures the base implementation, not the overridden one.
    # @param [String] content
    # @return [void]
    def <<(content)
      on_content(content)
    end
  end
end
