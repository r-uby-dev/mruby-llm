# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Rg LLM::Tool::Rg} class implements
  # a frontend to the popular 'rg' tool. The tool can
  # recursively search the current working directory
  # for one or more patterns.
  class Rg < self
    name "rg"
    description "recursively search the current directory for lines matching a pattern"
    parameter :patterns, Array[String], "one or more search patterns"
    parameter :path, String, "the path where the search is performed (default is cwd)"
    required %i[patterns]

    ##
    # @param [Array<String>] patterns
    # @param [String] path
    # @return [Hash]
    def call(patterns:, path: Dir.getwd)
      validate!(patterns:, path:)
      command = spawn(patterns:, path:)
      {ok: command.success?, stdout: command.stdout, stderr: command.stderr}
    end

    private

    def validate!(patterns:, path:)
      if path == "/"
        raise RuntimeError, "you can't search from the root of the filesystem"
      end
    end

    def spawn(patterns:, path:)
      LLM::Tool::Command.new("rg")
        .argv(*[*patterns].flat_map { ["-e", _1] })
        .argv(path)
        .spawn
    end
  end
end
