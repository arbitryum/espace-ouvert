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
    patch madmin_ehpad_profile_path(profile), params: {ehpad_profile: {status: "approved"}}

    assert profile.reload.approved?
    assert users(:pending).can_sign_in?
  end

  test "saving a care home with a new address geocodes it" do
    sign_in_as users(:admin)
    geocoded = {label: "x", city: "Paris", latitude: 48.85, longitude: 2.35}

    Geocoder.stub(:geocode, ->(_) { geocoded }) do
      post madmin_care_homes_path, params: {care_home: {name: "Maison Neuve", address: "1 rue Neuve, 75001 Paris"}}
    end

    assert_equal "Paris", CareHome.find_by!(name: "Maison Neuve").address_details.city
  end

  test "admin links a care home to an account and reads its requests" do
    sign_in_as users(:admin)
    care_home = create_care_home(name: "EHPAD Les Tilleuls")
    request = create_hosting_request(care_home)

    Geocoder.stub(:geocode, nil) do
      patch madmin_care_home_path(care_home), params: {care_home: {ehpad_profile_id: ehpad_profiles(:approved).id}}
    end
    assert_equal ehpad_profiles(:approved), care_home.reload.ehpad_profile

    get madmin_hosting_requests_path
    assert_response :success
    assert_match "Les Petits Pas", response.body

    get madmin_hosting_request_path(request)
    assert_response :success
    assert_match "Un atelier théâtre le mercredi.", response.body
  end

  test "admin uploads a shared document" do
    sign_in_as users(:admin)

    post madmin_shared_documents_path, params: {shared_document: {title: "Contrat d'accueil", published: "1", position: "1",
                                                                  file: fixture_file_upload("document.pdf", "application/pdf")}}

    document = SharedDocument.sole
    assert document.published?
    assert document.file.attached?
  end
end
