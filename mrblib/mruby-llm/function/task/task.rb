# frozen_string_literal: true

class LLM::Function
  ##
  # The {LLM::Function::Task::Task} class wraps a single function call
  # that runs cooperatively through the mruby-task scheduler. It is the
  # mruby equivalent of llm.rb's `:async` strategy: work is submitted to a
  # worker task and the result is bridged back through a {::Task::Queue}.
  #
  # The worker is spawned lazily in {#wait} or explicitly in {#spawn}.
  # Because the mruby root task cannot `join` or block on `Queue#pop`,
  # {#wait} polls the queue non-blockingly and yields to the scheduler
  # with `Task.pass` between polls.
  #
  # Interruption uses the queue-sentinel pattern (as in llm.rb's
  # `Async::Task`): {#interrupt!} pushes an {LLM::Interrupt} sentinel and
  # terminates the worker; {#wait} pops the sentinel and re-raises it.
  class Task::Task < LLM::Function::Task
    ##
    # @return [::Task, nil]
    attr_reader :task

    ##
    # @return [::Task::Queue, nil]
    attr_reader :queue

    ##
    # @param [LLM::Function] fn
    # @param [Hash] options
    # @return [LLM::Function::Task::Task]
    def initialize(fn, options = {})
      super
      @queue = nil
      @task = nil
      @alive = false
      @spawned = false
      @interrupted = false
    end

    ##
    # @return [LLM::Function::Task::Task]
    def spawn
      return if @guarded || @interrupted
      @queue = ::Task::Queue.new
      @alive = true
      fn = @function
      queue = @queue
      @task = ::Task.new do
        queue.push(fn.call)
      rescue LLM::Interrupt => e
        queue.push(e)
      rescue => ex
        queue.push(fn.error(ex))
      end
      @spawned = true
      self
    end

    ##
    # @return [Boolean]
    def alive?
      return false if @guarded || @interrupted
      return false unless @task
      @task.status != :DORMANT
    end

    ##
    # Push an interrupt sentinel to the result queue and terminate the
    # worker. The sentinel makes {#wait} raise {LLM::Interrupt}.
    # @return [nil]
    def interrupt!
      @interrupted = true
      return nil unless @queue
      @alive = false
      @queue.push(LLM::Interrupt.new)
      @task&.terminate
      nil
    end
    alias_method :cancel!, :interrupt!

    ##
    # Wait for the result queue to contain a value. Polls non-blockingly
    # so it also works from the mruby root task, which cannot block on
    # `Task::Queue#pop` or `Task#join`. The first wait caches the result,
    # so subsequent waits return the same {LLM::Function::Return}.
    # @return [LLM::Function::Return]
    def wait
      return @guarded if @guarded
      raise LLM::Interrupt if @interrupted
      spawn unless @spawned
      @result ||= begin
        loop do
          begin
            result = @queue.pop(true)
            @alive = false
            raise result if LLM::Interrupt === result
            break result
          rescue ::Task::Error
            unless alive?
              @alive = false
              break error_return
            end
            ::Task.pass
          end
        end
      end
    end
    alias_method :value, :wait

    ##
    # @return [Class]
    def group_class
      LLM::Function::Task::Group
    end

    private

    def error_return
      Return.new(@function.id, @function.name, {
        error: true,
        type: LLM::Error.name,
        message: "task did not produce a result"
      })
    end
  end
end
