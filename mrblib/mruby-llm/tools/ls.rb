# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Ls LLM::Tool::Ls} class implements
  # a tool that can list files and directories, with an
  # optional glob pattern to filter results.
  class Ls < self
    name "ls"
    description "list files and directories, optionally matching a glob pattern"
    parameter :path, String, "the directory to list (default is cwd)"
    parameter :glob, String, "an optional glob pattern (e.g. '*.rb', '**/*.md')"

    ##
    # @param [String] path
    # @param [String, nil] glob
    # @return [Hash]
    def call(path: Dir.getwd, glob: "*")
      validate!(path:)
      command = spawn(path:, glob:)
      entries = command.stdout.split("\n").sort.reject { _1 == path }
      {ok: command.success?, entries:, count: entries.size}
    end

    private

    def validate!(path:)
      raise "path does not exist: #{path}" unless Dir.exist?(path)
    end

    ##
    # Shells out to `find` for glob matching instead of implementing a
    # glob engine in Ruby (mruby has no `Dir.glob`). A `**/` prefix makes
    # the match recursive; anything else is limited to the given directory.
    # @param [String] path
    # @param [String] glob
    # @return [Command]
    def spawn(path:, glob:)
      recursive = glob.start_with?("**/")
      name = recursive ? glob.sub(%r{\A\*\*/}, "") : glob
      command = Command.new("find").argv(path)
      command = command.argv("-maxdepth", "1") unless recursive
      command.argv("-name", name).spawn
    end
  end
end
