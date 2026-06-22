class LineNotificationJob < ApplicationJob
  queue_as :default

  def perform(line_connection_id, message)
    line_connection = LineConnection.find_by(id: line_connection_id)
    return unless line_connection&.linked?

    LineNotificationSender.call(line_connection:, message:)
  end
end
