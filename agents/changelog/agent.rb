# frozen_string_literal: true

class Agent < LLM::Agent
  instructions :set_instructions
  tools :set_tools
  tracer :set_tracer
  concurrency :call

  def run
    talk("Let's update the changelog")
  end

  private

  def set_instructions
    File.read File.join(File.dirname(__FILE__), "prompt.md")
  end

  def set_tools
    [
      LLM::Tool::Git, LLM::Tool::ReadFile,
      LLM::Tool::Rg, LLM::Tool::SwapText,
      LLM::Tool::WriteFile
    ]
  end

  def set_tracer
    LLM::Tracer::Logger.new(llm, io: $stderr)
  end
end

def main(argv)
  llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
  Agent.new(llm).run
end

main(ARGV)
