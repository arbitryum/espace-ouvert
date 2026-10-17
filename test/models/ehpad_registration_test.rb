require "test_helper"

class EhpadRegistrationTest < ActiveSupport::TestCase
  VALID = {
    establishment_name: "EHPAD Les Tilleuls", establishment_address: "1 rue des Tilleuls, Paris", contact_name: "Marie Dupont",
    username: "ehpad-contact", email_address: "contact@example.org",
    password: "A-strong-password-123", password_confirmation: "A-strong-password-123", modules: [ "coworking" ]
  }.freeze

  test "creates a user with a pending profile" do
    assert EhpadRegistration.new(VALID).save

    user = User.find_by!(username: "ehpad-contact")
    assert user.ehpad_profile.pending?
    assert_not user.ehpad_profile.participates_in_spaces
    assert user.ehpad_profile.participates_in_coworking
    assert_not user.can_sign_in?
  end

  test "requires a module" do
    registration = EhpadRegistration.new(VALID.merge(modules: [ "" ]))

    assert_not registration.save
    assert_includes registration.errors[:modules], "Sélectionnez au moins un dispositif."
  end

  test "reports password and username errors from the user" do
    registration = EhpadRegistration.new(VALID.merge(username: "approved", password: "12345678", password_confirmation: "12345678"))

    assert_not registration.save
    assert registration.errors[:password].any?
    assert registration.errors[:username].any?
    assert_no_difference("EhpadProfile.count") { registration.save }
  end
end
