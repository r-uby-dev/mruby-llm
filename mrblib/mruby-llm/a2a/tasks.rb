# frozen_string_literal: true

class LLM::A2A
  ##
  # Groups task-oriented A2A operations.
  class Tasks
    ##
    # @param [LLM::A2A] a2a
    def initialize(a2a)
      @a2a = a2a
    end

    ##
    # Returns the current state of a task.
    # @param [String] task_id
    # @param [Integer, nil] history_length
    # @return [LLM::Object]
    def get(task_id, history_length: nil)
      @a2a.get_task(task_id, history_length:)
    end

    ##
    # Lists tasks with optional filtering.
    # @param [String, nil] context_id
    # @param [String, nil] status
    # @param [Integer, nil] history_length
    # @param [String, nil] status_timestamp_after
    # @param [Boolean, nil] include_artifacts
    # @param [Integer] page_size
    # @param [String, nil] page_token
    # @return [LLM::Object]
    def list(context_id: nil, status: nil, history_length: nil, status_timestamp_after: nil,
             include_artifacts: nil, page_size: 20, page_token: nil)
      @a2a.list_tasks(context_id:, status:, history_length:, status_timestamp_after:,
                      include_artifacts:, page_size:, page_token:)
    end

    ##
    # Cancels a task in progress.
    # @param [String] task_id
    # @return [LLM::Object]
    def cancel(task_id, metadata: nil)
      @a2a.cancel_task(task_id, metadata:)
    end

    ##
    # Subscribes to streaming updates for an existing task.
    # @param [String] task_id
    # @yieldparam [LLM::Object] event
    # @return [void]
    def subscribe(task_id, &on_event)
      @a2a.subscribe_to_task(task_id, &on_event)
    end
  end
end
