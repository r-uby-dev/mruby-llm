# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Git LLM::Tool::Git} class implements
  # a tool that can perform a select number of git actions.
  # The actions it can perform are read-only - at least for
  # the time being.
  class Git < self
    name "git"
    description "perform an action with git"
    parameter :action, Enum["log", "diff", "commit", "checkout", "branch", "show"], "the git operation to perform"
    parameter :arguments, Array[String], "one or more arguments for the git action"
    required %i[action]

    ##
    # @param [String] action
    # @param [Array<String>] arguments
    # @return [Hash]
    def call(action:, arguments: nil)
      command = spawn(action:, arguments:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    end

    private

    def spawn(action:, arguments:)
      LLM::Tool::Command
        .new("git")
        .argv(action)
        .argv(*[*arguments])
        .spawn
    end
  end
end
