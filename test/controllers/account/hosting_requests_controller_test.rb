require "test_helper"

class Account::HostingRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @care_home = create_care_home(name: "EHPAD Les Tilleuls", ehpad_profile: ehpad_profiles(:approved))
    @hosting_request = create_request(@care_home, "Les Petits Pas")
  end

  def create_request(care_home, organization, **attributes)
    care_home.hosting_requests.create!(organization_name: organization, contact_name: "Léa", email: "lea@example.org",
      message: "Un atelier théâtre le mercredi.", **attributes)
  end

  test "requires an approved establishment account" do
    get account_hosting_requests_path
    assert_redirected_to new_session_path

    sign_in_as users(:admin)
    get account_hosting_requests_path
    assert_redirected_to root_path
  end

  test "lists the requests of its care homes only, pending first" do
    create_request(@care_home, "Déjà acceptée", status: "accepted", answered_at: 1.day.ago, created_at: 1.minute.from_now)
    create_request(create_care_home(name: "Ailleurs"), "Autre établissement")
    sign_in_as users(:approved)

    get account_hosting_requests_path

    assert_equal ["Les Petits Pas", "Déjà acceptée"], css_select("article h2").map(&:text)
    assert_select "a", text: "Mes demandes"
  end

  test "accepting marks the request and offers a pre-written email" do
    sign_in_as users(:approved)

    patch accept_account_hosting_request_path(@hosting_request)

    assert @hosting_request.reload.accepted?
    assert @hosting_request.answered_at
    follow_redirect!
    link = css_select("a.btn-primary[href^='mailto:lea@example.org']").first
    assert_includes link["href"], "cc=approved%40example.com"
    assert_includes CGI.unescape(link["href"]), "EHPAD Les Tilleuls serait heureux d'accueillir Les Petits Pas"
  end

  test "refusing keeps the reason for us and emails the visitor" do
    sign_in_as users(:approved)
    get refusal_account_hosting_request_path(@hosting_request)
    assert_select "textarea[name='hosting_request[refusal_reason]']"

    assert_enqueued_email_with HostingRequestsMailer, :refusal, args: [@hosting_request] do
      patch refuse_account_hosting_request_path(@hosting_request), params: {hosting_request: {refusal_reason: " Salle en travaux "}}
    end

    assert @hosting_request.reload.refused?
    assert_equal "Salle en travaux", @hosting_request.refusal_reason
    assert_redirected_to account_hosting_requests_path
  end

  test "answered requests and other care homes' requests can't be answered" do
    other = create_request(create_care_home(name: "Ailleurs"), "Autre établissement")
    @hosting_request.accept!
    sign_in_as users(:approved)

    patch refuse_account_hosting_request_path(@hosting_request)
    assert_response :not_found
    patch accept_account_hosting_request_path(other)
    assert_response :not_found
    assert other.reload.pending?
  end
end
