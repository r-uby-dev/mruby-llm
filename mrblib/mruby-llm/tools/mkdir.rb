# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Mkdir LLM::Tool::Mkdir} class implements
  # a tool that can create a tree of new directories.
  class Mkdir < self
    name "mkdir"
    description "create a new directory"
    parameter :path, String, "the path to the directory"

    ##
    # @param [String] path
    # @return [Hash]
    def call(path:)
      command = spawn(path:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    end

    private

    def spawn(path:)
      LLM::Tool::Command
        .new("mkdir")
        .argv("-p", path)
        .spawn
    end
  end
end
