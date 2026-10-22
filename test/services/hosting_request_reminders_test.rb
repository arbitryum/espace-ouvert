require "test_helper"

class HostingRequestRemindersTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def create_request(care_home, created_at:, status: "pending")
    care_home.hosting_requests.create!(organization_name: "Structure", contact_name: "Léa", email: "lea@example.org",
      message: "Un besoin.", status:, created_at:)
  end

  test "reminds approved accounts with a request pending for a week, counting all pending ones" do
    care_home = create_care_home(ehpad_profile: ehpad_profiles(:approved))
    create_request(care_home, created_at: 8.days.ago)
    create_request(care_home, created_at: 1.day.ago)
    create_request(care_home, created_at: 9.days.ago, status: "accepted")
    create_request(create_care_home(ehpad_profile: ehpad_profiles(:pending)), created_at: 8.days.ago)
    create_request(create_care_home(contact_email: "accueil@ehpad.fr"), created_at: 8.days.ago)

    assert_enqueued_email_with HostingRequestsMailer, :reminder, args: [ehpad_profiles(:approved), 2] do
      HostingRequestRemindersJob.perform_now
    end
    assert_enqueued_emails 1
  end

  test "doesn't remind about recent requests" do
    create_request(create_care_home(ehpad_profile: ehpad_profiles(:approved)), created_at: 2.days.ago)

    assert_no_enqueued_emails { HostingRequestRemindersJob.perform_now }
  end

  test "is scheduled every Monday morning in production" do
    require "fugit"
    config = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml")).dig("production", "remind_pending_hosting_requests")
    task = SolidQueue::RecurringTask.from_configuration("remind", **config.symbolize_keys)

    assert task.valid?
    next_run = Fugit.parse_cronish(config["schedule"]).next_time.to_t.in_time_zone("Europe/Paris")
    assert_equal [1, 9], [next_run.wday, next_run.hour]
  end
end
