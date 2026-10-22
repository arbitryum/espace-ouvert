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

  test "shows the list and the map side by side, with city options" do
    care_home = create_care_home
    care_home.update!(address_details: create_address(city: "Montreuil", latitude: 48.86, longitude: 2.44))
    create_space(name: "Space liste", care_home:)

    get spaces_path

    assert_select "[data-controller=directory-map] [data-directory-map-id-param]", 1
    assert_select "[data-controller=directory-map] [data-directory-map-target=map]"
    assert_select "select[name=city] option[value=Montreuil]"
    assert_select "p", text: "1 espace"
  end

  test "marks spaces without slots when filtering by slot" do
    create_space(name: "Texte libre")

    get spaces_path(weekday: "0", moment: "morning")

    assert_select ".badge", text: "Créneaux à confirmer"
    assert_select "select[name=weekday] option[selected][value='0']"
  end

  test "map mode includes one marker per geocoded space" do
    care_home = create_care_home(name: "Maison Carte")
    care_home.update!(address_details: create_address(raw_address: "9 Rue Maria Helena Vieira da Silva, 75014 Paris",
      city: "Paris", postal_code: "75014", latitude: 48.8301, longitude: 2.3202))
    create_space(name: "Space map", care_home:)
    create_space(name: "Space without coordinates")

    get spaces_path(view_mode: "map")

    markers = JSON.parse(css_select("[data-controller=directory-map]").first["data-directory-map-markers-value"])
    assert_equal ["Space map"], markers.pluck("title")
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
    assert_select "td span", "09:30 – 12:00"
    assert_select "td", {text: "Mardi", count: 0}
    assert_no_match "Le matin", response.body
  end

  test "detail shows the availability text when the space has no active slot" do
    space = create_space(name: "Free text", availability: "À la demande.")
    space.recurring_availabilities.create!(weekday: 1, start_time: "14:00", end_time: "15:00", active: false)

    get space_path(space)

    assert_select "table", 0
    assert_match "À la demande.", response.body
  end

  test "availability shows one row per day, with each of its ranges" do
    space = create_space(name: "Two ranges")
    space.recurring_availabilities.create!(weekday: 0, start_time: "18:00", end_time: "22:00")
    space.recurring_availabilities.create!(weekday: 0, start_time: "09:00", end_time: "14:00")
    space.recurring_availabilities.create!(weekday: 2, start_time: "14:00", end_time: "22:00")

    get space_path(space)

    assert_select "tbody tr", 2
    assert_select "tbody tr:first-child td:last-child span" do |ranges|
      assert_equal ["09:00 – 14:00", "18:00 – 22:00"], ranges.map(&:text)
    end
  end

  test "detail of a future space is not found" do
    space = create_space(name: "Future space", days: 5)

    get space_path(space)

    assert_response :not_found
  end

  test "full spaces are tagged, with a grey pin" do
    care_home = create_care_home
    care_home.update!(address_details: create_address(latitude: 48.8566, longitude: 2.3522))
    create_space(name: "Salle pleine", care_home:, status: "full")

    get spaces_path

    assert_select "[data-directory-map-id-param] .badge", "Complet"
    marker = JSON.parse(css_select("[data-controller=directory-map]").first["data-directory-map-markers-value"]).first
    assert_equal [true, "Complet"], marker.values_at("full", "tag")
  end

  test "the page introduces the directory and offers to register a care home" do
    get spaces_path

    assert_select "a[href=?]", new_registration_path, text: "Vous voulez accueillir ? Référencez votre établissement"
    assert_select "#documents-title", 0
  end

  test "published documents are offered for download" do
    SharedDocument.create!(title: "Contrat d'accueil", description: "À signer avec l'établissement.", published: true,
      file: fixture_file_upload("document.pdf", "application/pdf"))
    SharedDocument.create!(title: "Brouillon", file: fixture_file_upload("document.pdf", "application/pdf"))

    get spaces_path

    assert_select "#documents-title", "Les documents pour bien démarrer"
    assert_select "section h3", "Contrat d'accueil"
    assert_select "section h3", {text: "Brouillon", count: 0}
    assert_select "section a[href*='/rails/active_storage/blobs/']", /Télécharger \(PDF, \d+ octets\)/
  end

  test "a linked document opens in a new tab" do
    SharedDocument.create!(title: "Charte du bien vivre ensemble", published: true,
      url: "https://drive.google.com/file/d/1wUtVUnbmlJzHJjkyYBmcNpPBTg92mgs1/view?usp=sharing")

    get spaces_path

    assert_select "section a[href^='https://drive.google.com/'][target=_blank][rel~=noopener]", "Ouvrir le document (drive.google.com)"
  end
end
