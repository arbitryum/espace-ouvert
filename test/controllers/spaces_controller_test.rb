require "test_helper"

class SpacesControllerTest < ActionDispatch::IntegrationTest
  test "home button links to the visitor home" do
    get spaces_path

    assert_select "a[href='/']"
  end

  test "no spaces" do
    get spaces_path

    assert_response :success
    assert_match "Aucun espace disponible pour le moment.", response.body
  end

  test "lists past spaces in list mode by default" do
    space = create_space(name: "Past space", days: -1)
    create_space(name: "Future space", days: 5)

    get spaces_path

    assert_select "h2", text: "Past space (Maison Test)"
    assert_no_match "Future space", response.body
    assert_select ".join a.btn-primary", text: "Liste"
    assert_select "a[href=?]", space_path(space)
  end

  test "pages show resized photos, lazily loaded" do
    space = create_space(name: "Photo space")
    space.images.create!(alt_text: "Salle", image: fixture_file_upload("photo.jpg", "image/jpeg"))

    get spaces_path
    assert_select "img[alt=Salle][loading=lazy][src*='/representations/']"

    get space_path(space)
    assert_select ".carousel img[alt=Salle][loading=eager][src*='/representations/']"
  end

  test "map mode includes one marker per geocoded space" do
    care_home = create_care_home(name: "Maison Carte")
    care_home.update!(address_details: create_address(raw_address: "9 Rue Maria Helena Vieira da Silva, 75014 Paris",
      city: "Paris", postal_code: "75014", latitude: 48.8301, longitude: 2.3202))
    create_space(name: "Space map", care_home:)
    create_space(name: "Space without coordinates")

    get spaces_path(view_mode: "map")

    markers = JSON.parse(css_select("[data-controller=spaces-map]").first["data-spaces-map-markers-value"])
    assert_equal [ "Space map" ], markers.pluck("name")
    assert_equal "9 Rue Maria Helena Vieira da Silva, 75014 Paris", markers.first["address"]
  end

  test "around me shows distances" do
    care_home = create_care_home
    care_home.update!(address_details: create_address(latitude: 48.8566, longitude: 2.3522))
    create_space(name: "Space proche", care_home:)

    get spaces_path(near_lat: "48.8566", near_lon: "2.3522", radius_km: "5", near_mode: "around_me")

    assert_select ".badge", text: "à 0,0 km"
    assert_select "input[name=location][value=?]", "Autour de moi (5km)"
  end

  test "detail of a past space shows its availability" do
    space = create_space(name: "Calendar space", days: -5, availability: "Le matin")
    space.recurring_availabilities.create!(weekday: 0, start_time: "09:30", end_time: "12:00")
    space.recurring_availabilities.create!(weekday: 1, start_time: "14:00", end_time: "15:00", active: false)

    get space_path(space)

    assert_response :success
    assert_select "h1", "Calendar space"
    assert_select "td", "Lundi"
    assert_select "td", "09:30 – 12:00"
    assert_select "td", { text: "Mardi", count: 0 }
    assert_match "Le matin", response.body
  end

  test "detail of a future space is not found" do
    space = create_space(name: "Future space", days: 5)

    get space_path(space)

    assert_response :not_found
  end
end
