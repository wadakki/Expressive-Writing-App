class LineNotificationConfig
  BOOLEAN = ActiveModel::Type::Boolean.new

  class << self
    def enabled?
      value = ENV["LINE_NOTIFICATION_ENABLED"]
      return !Rails.env.production? if value.nil?

      BOOLEAN.cast(value) == true
    end
  end
end
