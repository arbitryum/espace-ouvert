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
end
