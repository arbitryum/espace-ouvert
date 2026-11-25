require "test_helper"

class AdminGuideTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "admin browses and edits guide pages" do
    page = GuidePage.create!(section: "Démarrer", title: "Bienvenue", slug: "bienvenue", body: "<p>Bonjour</p>")

    get madmin_guide_pages_path
    assert_response :success
    assert_match "Bienvenue", response.body

    get madmin_guide_page_path(page)
    assert_response :success

    get edit_madmin_guide_page_path(page)
    assert_response :success

    patch madmin_guide_page_path(page), params: {guide_page: {title: "Accueil"}}
    assert_equal "Accueil", page.reload.title
  end

  test "admin browses guide readers" do
    reader = GuideReader.create!(email_address: "lecteur@example.org")

    get madmin_guide_readers_path
    assert_response :success
    assert_match "lecteur@example.org", response.body

    get madmin_guide_reader_path(reader)
    assert_response :success
  end
end
