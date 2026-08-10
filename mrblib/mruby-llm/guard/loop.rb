# frozen_string_literal: true

class LLM::Guard
  ##
  # {LLM::Guard::Loop LLM::Guard::Loop} is the built-in loop-detection
  # guard. It detects when a context is repeating the same tool-call
  # pattern instead of making progress, and returns an in-band
  # {LLM::Function::Return LLM::Function::Return} so {LLM::Context
  # LLM::Context} can block the pending tool work.
  class Loop < self
    ##
    # The default number of repeated tool-call patterns required before
    # the guard intervenes.
    # @return [Integer]
    DEFAULT_THRESHOLD = 3

    ##
    # Checks the current context for repeated tool-call patterns.
    #
    # This method inspects assistant tool calls only. It reduces each call
    # to a `[tool_name, arguments]` signature and checks whether the tail
    # of the sequence is repeating.
    #
    # @param [LLM::Function] function
    #  The pending function being decided about. Only its id and name are
    #  used to build the return.
    # @param [Integer] threshold
    #  How many repeated tool-call patterns must appear at the tail of the
    #  sequence before the guard returns a warning.
    # @param [Hash] opts
    #  Additional per-call options (ignored).
    # @return [LLM::Function::Return, nil]
    #  Returns a tool return that blocks this function's pending call, or
    #  nil when execution should continue.
    def call(function:, threshold: DEFAULT_THRESHOLD, **opts)
      repetitions = detect(messages.to_a, threshold)
      return unless repetitions
      function.return(error: true, type: "guard_error", message: warning(repetitions))
    end

    private

    def detect(messages, threshold)
      signatures = extract_signatures(messages)
      return if signatures.size < threshold
      check_repeating_pattern(signatures, threshold)
    end

    def warning(repetitions)
      <<~MSG
        SYSTEM NOTICE: Repeated tool-call pattern detected - the same pattern has repeated #{repetitions} times.
        You are stuck in a loop and not making progress. Stop and try a fundamentally different approach:
        - Re-read the relevant context before retrying
        - Try a different tool or strategy
        - Break the problem into smaller steps
        - If a tool keeps failing, investigate why before retrying
      MSG
    end

    def extract_signatures(messages)
      messages
        .select(&:assistant?)
        .flat_map { |message| message.functions.map { [_1.name.to_s, _1.arguments.to_h] } }
    end

    def check_repeating_pattern(sequence, threshold)
      max_pattern_len = sequence.size / threshold
      (1..max_pattern_len).each do |pattern_len|
        count = count_tail_repetitions(sequence, pattern_len)
        return count if count >= threshold
      end
      nil
    end

    def count_tail_repetitions(sequence, length)
      return 0 if sequence.size < length
      pattern = sequence.last(length)
      count = 1
      pos = sequence.size - length
      while pos >= length
        candidate = sequence[(pos - length)...pos]
        break unless candidate == pattern
        count += 1
        pos -= length
      end
      count
    end
  end
end
