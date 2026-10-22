require "test_helper"

class CoworkingControllerTest < ActionDispatch::IntegrationTest
  test "home button links to the visitor home" do
    get coworking_path

    assert_response :success
    assert_select "a[href='/']"
  end

  test "directory only lists published projects" do
    CoworkingProject.create!(name: "Projet publié", organization_name: "Collectif local", description: "Un projet de proximité.",
      location: "Paris", status: "seeking", published: true)
    CoworkingProject.create!(name: "Projet brouillon", organization_name: "Collectif local", description: "Ne doit pas apparaître.",
      location: "Lyon", status: "draft", published: false)

    get coworking_projects_path

    assert_response :success
    assert_match "Projet publié", response.body
    assert_match "Recherche d&#39;un établissement", response.body
    assert_no_match "Projet brouillon", response.body
  end

  test "directory shows projects beside a map of their care homes" do
    care_home = create_care_home(name: "Maison Coworking")
    care_home.update!(address_details: create_address(raw_address: "8 rue de Paris, 93100 Montreuil", latitude: 48.86, longitude: 2.44))
    on_map = CoworkingProject.create!(name: "Projet localisé", organization_name: "Collectif", description: "Sur la carte.",
      location: "Montreuil", status: "seeking", published: true, care_home:)
    CoworkingProject.create!(name: "Projet sans établissement", organization_name: "Collectif", description: "Pas sur la carte.",
      location: "Lyon", status: "seeking", published: true)

    get coworking_projects_path

    markers = JSON.parse(css_select("[data-controller=directory-map]").first["data-directory-map-markers-value"])
    assert_equal [["Projet localisé", "8 rue de Paris, 93100 Montreuil"]], markers.map { |marker| marker.values_at("title", "address") }
    assert_select "[data-directory-map-id-param='#{on_map.id}']", 1
    assert_select "[data-directory-map-id-param]", 2
    assert_select "p", text: "2 projets"
  end
end
