require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  PARAMS = {
    establishment_name: "EHPAD Les Tilleuls", establishment_address: "1 rue des Tilleuls, Paris", contact_name: "Marie Dupont",
    email_address: "contact@example.org",
    password: "A-strong-password-123", password_confirmation: "A-strong-password-123"
  }.freeze

  test "form has password controls and live validation" do
    get new_registration_path

    assert_response :success
    assert_select "[data-controller=password-rules]"
    assert_select "[data-password-rules-target=rule][data-rule=length]"
    assert_select "[data-controller=password-visibility]", count: 2
  end

  test "registration creates a pending profile" do
    post registrations_path, params: {ehpad_registration: PARAMS.merge(modules: ["", "coworking"])}

    assert_redirected_to pending_registration_path
    profile = User.find_by!(email_address: "contact@example.org").ehpad_profile
    assert profile.pending?
    assert_not profile.participates_in_spaces
    assert profile.participates_in_coworking
  end

  test "registration requires a module" do
    post registrations_path, params: {ehpad_registration: PARAMS.merge(modules: [""])}

    assert_response :unprocessable_entity
    assert_match "Sélectionnez au moins un dispositif.", response.body
    assert_not User.exists?(email_address: "contact@example.org")
  end
end
