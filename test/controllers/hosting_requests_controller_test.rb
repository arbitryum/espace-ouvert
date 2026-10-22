require "test_helper"

class HostingRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @care_home = create_care_home(name: "EHPAD Les Tilleuls", contact_email: "accueil@ehpad.fr", legal_status: "public")
    @space = create_space(name: "Salle polyvalente", care_home: @care_home)
  end

  def valid_params(**overrides)
    {hosting_request: {kind: "coworking", first_name: "Sam", last_name: "Durand", email: "sam@example.org",
                       organization_name: "Collectif", activity: "Studio de design", website: "https://collectif.example",
                       team_size: "3", days_per_week: "2", weekdays: ["", "1", "3"], needs: ["", "wifi"], compensation: "time",
                       **overrides}}
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

  test "the form asks each kind's questions, with the care home's slots" do
    @space.recurring_availabilities.create!(weekday: 2, start_time: "14:00", end_time: "18:00")

    get new_care_home_hosting_request_path(@care_home)

    assert_select "[data-kind=coworking] input[name='hosting_request[team_size]']"
    assert_select "[data-kind=coworking] input[name='hosting_request[weekdays][]']", 6
    assert_select "[data-kind=association] textarea[name='hosting_request[activity_type]']"
    assert_select "[data-kind=association] input[name='hosting_request[slots][]'][value=?]", "Salle polyvalente – Mercredi 14:00 – 18:00"
  end

  test "sending a coworking request saves it and emails the care home and the visitor" do
    assert_enqueued_emails 2 do
      post care_home_hosting_requests_path(@care_home), params: valid_params
    end

    request = HostingRequest.last
    assert_redirected_to care_home_path(@care_home)
    assert_equal [@care_home, "coworking", "pending", "Sam Durand", [1, 3], ["wifi"], "time"],
      [request.care_home, request.kind, request.status, request.contact_name, request.weekdays, request.needs, request.compensation]
  end

  test "sending an association request keeps the chosen slots" do
    @space.recurring_availabilities.create!(weekday: 2, start_time: "14:00", end_time: "18:00")
    slot = "Salle polyvalente – Mercredi 14:00 – 18:00"

    post care_home_hosting_requests_path(@care_home), params: {hosting_request: {kind: "association", first_name: "Léa",
                                                                                 last_name: "Martin", email: "lea@example.org", organization_name: "Les Petits Pas", activity: "Théâtre",
                                                                                 space_id: @space.id, activity_type: "Atelier théâtre", attendees: "12", slots: ["", slot], contribution: "Un spectacle"}}

    request = HostingRequest.last
    assert_equal [@space, [slot], 12, "Un spectacle"], [request.space, request.slots, request.attendees, request.contribution]
  end

  test "an invalid request shows the form again" do
    assert_no_difference -> { HostingRequest.count } do
      post care_home_hosting_requests_path(@care_home), params: valid_params(email: "pas-un-email")
    end

    assert_response :unprocessable_content
    assert_select ".text-error", "n'est pas valide"
  end

  test "a bot filling the hidden field sends nothing" do
    assert_no_enqueued_emails do
      assert_no_difference -> { HostingRequest.count } do
        post care_home_hosting_requests_path(@care_home), params: valid_params.merge(website_url: "http://spam.example")
      end
    end

    assert_redirected_to care_home_path(@care_home)
  end
end
