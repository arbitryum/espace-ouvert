require "test_helper"

class CoworkingControllerTest < ActionDispatch::IntegrationTest
  test "home button links to the visitor home" do
    get coworking_path

    assert_response :success
    assert_select "a[href='/']"
  end

  test "the coworking page links to the directory and the registration form" do
    get coworking_path

    assert_select "a[href=?]", coworking_directory_path
    assert_select "a[href=?]", new_registration_path
  end

  test "the directory lists care homes offering coworking, approved ones only, full ones last" do
    full = create_care_home(name: "Résidence Pleine", offers_coworking: true, coworking_full: true)
    hosting = create_care_home(name: "Résidence Accueillante", offers_coworking: true, ehpad_profile: ehpad_profiles(:approved))
    hosting.update!(address_details: create_address(raw_address: "8 rue de Paris, 93100 Montreuil", latitude: 48.86, longitude: 2.44))
    hosting.hosting_requests.new(kind: "coworking", status: "accepted", organization_name: "Collectif", contact_name: "Sam",
      email: "sam@example.org", message: "Une équipe de deux.").save!(validate: false)
    create_care_home(name: "Résidence en attente", offers_coworking: true, ehpad_profile: ehpad_profiles(:pending))
    create_care_home(name: "Résidence sans coworking")

    get coworking_directory_path

    assert_response :success
    assert_equal ["Résidence Accueillante", "Résidence Pleine"], css_select("article h2").map { |title| title.text.strip }
    assert_select "article .badge", "Accueille déjà une équipe"
    assert_select "article .badge", "Complet"
    assert_select "a[href=?]", new_care_home_hosting_request_path(hosting, kind: "coworking")
    assert_select "a[href=?]", new_registration_path
    markers = JSON.parse(css_select("[data-controller=directory-map]").first["data-directory-map-markers-value"])
    assert_equal [["Résidence Accueillante", "8 rue de Paris, 93100 Montreuil", false, "Accueille déjà une équipe"]],
      markers.map { |marker| marker.values_at("title", "address", "full", "tag") }
    assert_not full.reload.hosting_coworking?
  end

  test "the old projects address redirects to the directory" do
    get "/coworking/projets"

    assert_redirected_to "/coworking/annuaire"
  end
end
