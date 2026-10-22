# Weekly nudge to establishments with requests left pending for a week or more
# (HostingRequestRemindersJob, scheduled in config/recurring.yml).
class HostingRequestReminders
  DELAY = 7.days

  def self.run(output: Rails.logger)
    late = HostingRequest.pending.where(created_at: ..DELAY.ago)
    profiles = EhpadProfile.approved.where(id: CareHome.where(id: late.select(:care_home_id)).select(:ehpad_profile_id))
    profiles.includes(:user, :care_homes).find_each do |profile|
      count = HostingRequest.pending.where(care_home: profile.care_homes).count
      HostingRequestsMailer.reminder(profile, count).deliver_later
      output.info "[HostingRequestReminders] #{profile.user.email_address}: #{count} pending"
    end
  end
end
