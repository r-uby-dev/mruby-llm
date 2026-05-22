# frozen_string_literal: true

class LLM::A2A
  ##
  # Generic A2A protocol error.
  Error = Class.new(LLM::Error) do
    ##
    # @return [Integer, nil]
    attr_reader :code

    ##
    # @return [Object, nil]
    attr_reader :data

    ##
    # @param [String] message
    # @param [Integer, nil] code
    # @param [Object, nil] data
    def initialize(message, code = nil, data = nil)
      super(message)
      @code = code
      @data = data
    end
  end

  ##
  # Raised when the agent card cannot be fetched or parsed.
  AgentCardError = Class.new(Error)

  ##
  # Raised when a task is not found.
  TaskNotFoundError = Class.new(Error)

  ##
  # Raised when a task cannot be cancelled.
  TaskNotCancelableError = Class.new(Error)

  ##
  # Raised when the agent does not support the requested operation.
  UnsupportedOperationError = Class.new(Error)

  ##
  # Raised when a content type is not supported.
  ContentTypeNotSupportedError = Class.new(Error)

  ##
  # Raised when the A2A protocol version is not supported.
  VersionNotSupportedError = Class.new(Error)
end
