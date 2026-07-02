# frozen_string_literal: true

class LLM::Tool
  ##
  # @api private
  class Command
    ##
    # @return [Boolean]
    attr_reader :success

    ##
    # @return [String]
    attr_reader :stdout

    ##
    # @return [String]
    attr_reader :stderr

    ##
    # @param [String] name
    #  The command name
    # @return [LLM::Tool::Command]
    def initialize(name)
      @name = name.to_s
      @args = []
    end

    ##
    # Add one or more arguments.
    # @param [Array<String>] args
    # @return [LLM::Tool::Command]
    def argv(*args)
      @args.concat(args.map(&:to_s))
      self
    end

    ##
    # @return [Boolean]
    def success?
      @success
    end

    ##
    # Spawn the command and capture output.
    # @return [LLM::Tool::Command]
    def spawn
      command = [@name, *@args].join(" ")
      @stdout = ::IO.popen(command, "r") { |io| io.read }
      @success = $?.success?
      self
    end
  end
end
