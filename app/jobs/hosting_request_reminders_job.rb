# Scheduled every Monday morning in config/recurring.yml.
class HostingRequestRemindersJob < ApplicationJob
  def perform = HostingRequestReminders.run
end
