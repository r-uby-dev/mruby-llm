# frozen_string_literal: true

class LLM::A2A
  ##
  # Groups push notification configuration operations.
  class Notifications
    ##
    # @param [LLM::A2A] a2a
    def initialize(a2a)
      @a2a = a2a
    end

    ##
    # Creates a push notification configuration for a task.
    # @param [String] task_id
    # @param [String] url
    # @param [String, nil] token
    # @param [Hash, nil] authentication
    # @param [String, nil] id
    # @return [LLM::Object]
    def create(task_id, url:, token: nil, authentication: nil, id: nil)
      @a2a.create_task_push_notification_config(task_id, url:, token:, authentication:, id:)
    end

    ##
    # Retrieves a push notification configuration for a task.
    # @param [String] task_id
    # @param [String] id
    # @return [LLM::Object]
    def get(task_id, id)
      @a2a.get_task_push_notification_config(task_id, id)
    end

    ##
    # Lists push notification configurations for a task.
    # @param [String] task_id
    # @param [Integer, nil] page_size
    # @param [String, nil] page_token
    # @return [LLM::Object]
    def list(task_id, page_size: nil, page_token: nil)
      @a2a.list_task_push_notification_configs(task_id, page_size:, page_token:)
    end

    ##
    # Deletes a push notification configuration for a task.
    # @param [String] task_id
    # @param [String] id
    # @return [LLM::Object]
    def delete(task_id, id)
      @a2a.delete_task_push_notification_config(task_id, id)
    end
  end
end
