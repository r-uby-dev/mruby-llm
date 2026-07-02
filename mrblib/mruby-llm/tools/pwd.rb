# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Pwd LLM::Tool::Pwd} class implements
  # a tool that can reveal the current working directory.
  class Pwd < self
    name "pwd"
    description "returns the current working directory"

    ##
    # @return [Hash]
    def call
      {ok: true, cwd: Dir.getwd}
    end
  end
end
