require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "requires to sign in" do
    get madmin_root_path

    assert_redirected_to new_session_path
  end

  test "is reserved to admins" do
    sign_in_as users(:approved)

    get madmin_ehpad_profiles_path

    assert_redirected_to root_path
  end

  test "admin approves an establishment, which can then sign in" do
    sign_in_as users(:admin)
    profile = ehpad_profiles(:pending)

    get madmin_ehpad_profiles_path
    assert_response :success
    patch madmin_ehpad_profile_path(profile), params: { ehpad_profile: { status: "approved" } }

    assert profile.reload.approved?
    assert users(:pending).can_sign_in?
  end

  test "saving a care home with a new address geocodes it" do
    sign_in_as users(:admin)
    geocoded = { label: "x", city: "Paris", latitude: 48.85, longitude: 2.35 }

    Geocoder.stub(:geocode, ->(_) { geocoded }) do
      post madmin_care_homes_path, params: { care_home: { name: "Maison Neuve", address: "1 rue Neuve, 75001 Paris" } }
    end

    assert_equal "Paris", CareHome.find_by!(name: "Maison Neuve").address_details.city
  end
end
