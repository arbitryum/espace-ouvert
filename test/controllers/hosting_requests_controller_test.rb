require "test_helper"

class HostingRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @care_home = create_care_home(name: "EHPAD Les Tilleuls", contact_email: "accueil@ehpad.fr", legal_status: "public")
    @space = create_space(name: "Salle polyvalente", care_home: @care_home)
  end

  def valid_params(**overrides)
    {hosting_request: {kind: "coworking", space_id: @space.id, organization_name: "Collectif", contact_name: "Léa",
                       email: "lea@example.org", message: "Trois personnes, deux jours par semaine.", **overrides}}
  end

  test "the care home page lists its spaces and links to the form" do
    create_space(name: "Brouillon", care_home: @care_home, publication_status: "draft")

    get care_home_path(@care_home)

    assert_select "h1", "EHPAD Les Tilleuls"
    assert_select "li", "Statut : Public"
    assert_select "h3", "Salle polyvalente"
    assert_select "h3", {text: "Brouillon", count: 0}
    assert_select "a[href=?]", new_care_home_hosting_request_path(@care_home)
    assert_no_match "accueil@ehpad.fr", response.body
  end

  test "the space page links to the form with the space selected" do
    get space_path(@space)
    assert_select "a[href=?]", new_care_home_hosting_request_path(@care_home, space_id: @space.id)

    get new_care_home_hosting_request_path(@care_home, space_id: @space.id)
    assert_select "select[name='hosting_request[space_id]'] option[selected][value='#{@space.id}']"
    assert_select "input[name='hosting_request[kind]'][value=association][checked]"
  end

  test "sending saves the request and emails the care home and the visitor" do
    assert_enqueued_emails 2 do
      post care_home_hosting_requests_path(@care_home), params: valid_params
    end

    request = HostingRequest.last
    assert_redirected_to care_home_path(@care_home)
    assert_equal [@care_home, @space, "coworking", "pending"], [request.care_home, request.space, request.kind, request.status]
  end

  test "an invalid request shows the form again" do
    assert_no_difference -> { HostingRequest.count } do
      post care_home_hosting_requests_path(@care_home), params: valid_params(email: "pas-un-email")
    end

    assert_response :unprocessable_content
    assert_select ".text-error", /Email/
  end

  test "a bot filling the hidden field sends nothing" do
    assert_no_enqueued_emails do
      assert_no_difference -> { HostingRequest.count } do
        post care_home_hosting_requests_path(@care_home), params: valid_params.merge(website: "http://spam.example")
      end
    end

    assert_redirected_to care_home_path(@care_home)
  end
end
