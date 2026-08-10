# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::Which LLM::Tool::Which} class implements
  # a tool that locates an executable on the system PATH.
  #
  # This lets an agent discover whether a command it intends
  # to use is actually available before attempting to run it.
  # For example, checking `which("rg")` before a search, or
  # `which("git")` before a version control operation, avoids
  # a failed subprocess and lets the agent adapt its strategy
  # when a tool is missing.
  #
  # @note
  #  The mruby runtime has no `File.executable?`, so this
  #  implementation resolves a command to the first PATH
  #  directory that contains a file with that name.
  class Which < self
    name "which"
    description "locate an executable on the system PATH"
    parameter :name, String, "the name of the executable to find"
    required %i[name]

    ##
    # @param [String] name
    # @return [Hash]
    def call(name:)
      path = paths.find { File.exist?(File.join(_1, name)) }
      {ok: !!path, path:}
    end

    private

    ##
    # @return [Array<String>]
    def paths
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR)
    end
  end
end
