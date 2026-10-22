require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home offers both products" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", spaces_path
    assert_select "a[href=?]", coworking_path
  end

  test "home presents the project, how it works and key figures" do
    create_space(name: "Ouvert")
    create_space(name: "Brouillon", publication_status: "draft")

    get root_path

    assert_select "h2", "Le projet en bref"
    assert_select "a[href=?]", new_registration_path, text: "Inscrire son établissement"
    assert_select "ol li", 3
    assert_select "a[href=?]", coworking_path, text: "Je cherche un espace pour faire du coworking"
    assert_select ".stat-value", "1"
    assert_select ".stat-desc", "établissement inscrit dans l'annuaire, prêt à vous accueillir"
  end

  test "home hides key figures without listed spaces" do
    get root_path

    assert_select ".stats", 0
  end

  test "page titles escape apostrophes once" do
    get spaces_path

    assert_select "title", "Accueil d'association - Espace-ouvert"
    assert_no_match "&amp;#39;", response.body
  end
end
