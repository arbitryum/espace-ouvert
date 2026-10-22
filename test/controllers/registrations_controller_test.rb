require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  PARAMS = {
    establishment_name: "EHPAD Les Tilleuls", legal_status: "associatif", street: "1 rue des Tilleuls", postal_code: "75011",
    city: "Paris", contact_name: "Marie Dupont", email_address: "contact@example.org",
    password: "A-strong-password-123", password_confirmation: "A-strong-password-123"
  }.freeze

  test "form has password controls, both sections and a space template" do
    get new_registration_path

    assert_response :success
    assert_select "[data-controller=password-rules]"
    assert_select "[data-password-rules-target=rule][data-rule=length]"
    assert_select "[data-controller=password-visibility]", count: 2
    assert_select "[data-module=coworking] input[type=radio][name='ehpad_registration[coworking_space]']", 2
    assert_select "[data-module=spaces] input[name='ehpad_registration[spaces][0][slots][6][end_time]']"
    assert_select "template input[name='ehpad_registration[spaces][__INDEX__][name]']"
  end

  test "registration creates a pending profile and its care home" do
    Geocoder.stub(:geocode, nil) do
      post registrations_path, params: {ehpad_registration: PARAMS.merge(modules: ["", "coworking"], coworking_space: "yes",
        coworking_photos: [fixture_file_upload("photo.jpg", "image/jpeg")])}
    end

    assert_redirected_to pending_registration_path
    assert_match "annuaire d'établissements prêts à accueillir une équipe en coworking", flash[:notice]
    profile = User.find_by!(email_address: "contact@example.org").ehpad_profile
    assert profile.pending?
    assert profile.participates_in_coworking
    assert profile.care_homes.sole.offers_coworking
  end

  test "registration with association spaces" do
    space = {name: "Salle polyvalente", description: "40 m²", photos: [fixture_file_upload("photo.jpg", "image/jpeg")],
             slots: {"0" => {enabled: "1", start_time: "09:00", end_time: "12:00"}}}

    Geocoder.stub(:geocode, nil) do
      post registrations_path, params: {ehpad_registration: PARAMS.merge(modules: ["spaces"], spaces: {"0" => space})}
    end

    assert_redirected_to pending_registration_path
    space = CareHome.find_by!(name: "EHPAD Les Tilleuls").spaces.sole
    assert space.draft?
    assert_equal [0], space.recurring_availabilities.map(&:weekday)
    assert_equal 1, space.images.count
  end

  test "registration requires a module" do
    post registrations_path, params: {ehpad_registration: PARAMS.merge(modules: [""])}

    assert_response :unprocessable_entity
    assert_match "Sélectionnez au moins un dispositif.", response.body
    assert_not User.exists?(email_address: "contact@example.org")
  end
end
