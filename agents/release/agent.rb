# frozen_string_literal: true

require "llm"

class Agent < LLM::Agent
  instructions :set_instructions
  tools :set_tools
  tracer :set_tracer
  concurrency :call

  def run(version:)
    talk("Let's prepare the #{version} release")
  end

  private

  def set_instructions
    File.read File.join(__dir__, "prompt.md")
  end

  def set_tools
    [LLM::Tool::Git, LLM::Tool::ReadFile, LLM::Tool::Rg, LLM::Tool::SwapText]
  end

  def set_tracer
    LLM::Tracer::Logger.new(llm, io: $stderr)
  end
end

def main(argv)
  version = argv[0]
  if version.nil? || version.strip.empty?
    warn "release: provide a version"
  else
    llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
    Agent.new(llm).run(version:)
  end
end

main(ARGV) if $PROGRAM_NAME == __FILE__
