# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::EditFile LLM::Tool::EditFile} class
  # implements a tool that can substitute one piece of
  # text for another piece of text in a given file.
  class EditFile < self
    name "edit-file"
    description "Replace an exact snippet in a file"
    parameter :path, String, "Path to file"
    parameter :before, String, "Exact text to replace"
    parameter :after, String, "Replacement text"
    parameter :expected_count, Integer, "How many matches should be replaced"
    required %i[path before after]

    ##
    # @param [String] path
    # @param [String] before
    # @param [String] after
    # @param [Integer] expected_count
    # @return [Hash]
    def call(path:, before:, after:, expected_count: 1)
      content = File.read(path)
      count = content.scan(before).length
      raise "expected #{expected_count} match(es), found #{count}" unless count == expected_count.to_i
      File.open(path, "w") { _1.write(content.sub(before, after)) }
      {ok: true, replaced: count}
    end
  end
end
