require "test_helper"

class CareHomeRequestsTest < ActiveSupport::TestCase
  test "requests go to the approved account, else the contact email, else the admins" do
    care_home = create_care_home(contact_email: "accueil@ehpad.fr")
    assert_equal ["accueil@ehpad.fr"], care_home.request_recipients

    care_home.update!(ehpad_profile: ehpad_profiles(:approved))
    assert_equal ["approved@example.com"], care_home.request_recipients

    care_home.update!(ehpad_profile: ehpad_profiles(:pending), contact_email: "")
    assert_equal ["admin@example.com"], care_home.request_recipients
  end
end
