Sidekiq::Cron.configure do |config|
  config.cron_schedule_file = Rails.root.join("config/schedule.yml").to_s
end
