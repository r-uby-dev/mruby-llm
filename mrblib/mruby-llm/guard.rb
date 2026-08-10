# frozen_string_literal: true

module LLM
  ##
  # {LLM::Guard LLM::Guard} is the superclass for context-level
  # supervisors in llm.rb.
  #
  # A guard is bound to a context and decides whether a tool call should
  # be blocked before it runs. Each subclass implements {#call} and returns
  # an {LLM::Function::Return LLM::Function::Return} that closes the
  # pending tool call, or `nil` when execution should continue. The guard
  # is stamped onto the functions the context binds, so it runs whenever a
  # task is spawned — including tool calls queued from a stream. The
  # built-in implementation is {LLM::Guard::Loop LLM::Guard::Loop}, which
  # detects repeated tool-call patterns. {LLM::Guard::Null LLM::Guard::Null}
  # is a no-op and the default.
  #
  # {LLM::Agent LLM::Agent} enables {LLM::Guard::Loop LLM::Guard::Loop}
  # by default through its wrapped context.
  class Guard
    ##
    # @return [LLM::Context]
    attr_reader :ctx

    ##
    # @param ctx [LLM::Context, LLM::Agent]
    # @return [LLM::Guard]
    def initialize(ctx)
      @ctx = LLM::Agent === ctx ? ctx.instance_variable_get(:@ctx) : ctx
    end

    ##
    # @abstract
    # @param [LLM::Function] function
    #  The pending function the guard is deciding about.
    # @param opts [Hash] Per-call options
    # @return [LLM::Function::Return, nil]
    #  A tool return that closes this function's pending call when it
    #  should be blocked, or nil when execution should continue.
    def call(function:, **opts)
      raise NotImplementedError
    end

    private

    ##
    # @return [LLM::Stream]
    def stream
      @ctx.params[:stream]
    end

    ##
    # @return [LLM::Buffer]
    def messages
      @ctx.messages
    end
  end
end
