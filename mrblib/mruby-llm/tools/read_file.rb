# frozen_string_literal: true

class LLM::Tool
  ##
  # The {LLM::Tool::ReadFile LLM::Tool::ReadFile} class implements
  # a tool that can read the contents of a file within an optional
  # range of lines.
  class ReadFile < self
    name "read-file"
    description "read the contents of a file"
    parameter :path, String, "the path to the file"
    parameter :start, Integer, "start line number"
    parameter :stop, Integer, "stop line number"
    required %i[path]

    ##
    # @param [String] path
    # @param [Integer] start
    # @param [Integer] stop
    # @return [Hash]
    def call(path:, start: 1, stop: -1)
      content = nil
      cursor = 1
      File.open(path, "r") do |f|
        while cursor < start
          f.gets
          cursor += 1
        end
        if stop == -1
          content = f.read
        else
          content = start.upto(stop).map { f.gets }.join
        end
      end
      {ok: true, content: content}
    end
  end
end
