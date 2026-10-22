require "test_helper"

class GuidesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @page = GuidePage.create!(section: "Introduction", title: "Identifier le bon espace", slug: "identifier-le-bon-espace",
      body: %(<p>Contenu réservé</p><img data-guide-image="42" alt="">))
    @page.images.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")
  end

  test "without access, the guide shows its boxes and the request form, not the content" do
    get guide_path

    assert_response :success
    assert_select "h2", "Introduction"
    assert_select "a[href=?]", guide_path(page: "identifier-le-bon-espace"), /Identifier le bon espace/
    assert_select "a[href=?]", guide_page_path(@page), 0
    assert_select "form[action=?] input[type=email][name=email_address]", guide_access_path
    assert_select "dialog", 0
    assert_no_match "Contenu réservé", response.body
  end

  test "opening a box without access asks for the email for that page" do
    get guide_path(page: "identifier-le-bon-espace")

    assert_select "dialog[open] h2", "Pour lire « Identifier le bon espace »"
    assert_select "dialog form input[name=page][value=?]", "identifier-le-bon-espace"
    assert_no_match "Contenu réservé", response.body
  end

  test "without access, pages open the email form for them and images are not found" do
    get guide_page_path(@page)
    assert_redirected_to guide_path(page: "identifier-le-bon-espace")

    get guide_image_path(@page.images.attachments.first)
    assert_response :not_found
  end

  test "requesting access saves the email and sends the link" do
    assert_difference "GuideReader.count" do
      post guide_access_path, params: {email_address: " Lea@Example.org "}
    end

    assert_redirected_to guide_path
    reader = GuideReader.last
    assert_equal "lea@example.org", reader.email_address
    assert_enqueued_email_with GuideMailer, :access_link, args: [reader, {page: nil}]
  end

  test "the link requested from a box leads to its page" do
    post guide_access_path, params: {email_address: "lea@example.org", page: "identifier-le-bon-espace"}
    reader = GuideReader.last
    assert_enqueued_email_with GuideMailer, :access_link, args: [reader, {page: @page}]

    get guide_access_link_path(reader.generate_token_for(:access), page: "identifier-le-bon-espace")
    assert_redirected_to guide_page_path(@page)
  end

  test "an unknown page in the link leads to the guide" do
    reader = GuideReader.create!(email_address: "lea@example.org")

    get guide_access_link_path(reader.generate_token_for(:access), page: "https://evil.example")

    assert_redirected_to guide_path
  end

  test "requesting access again doesn't duplicate the reader" do
    GuideReader.create!(email_address: "lea@example.org")

    assert_no_difference("GuideReader.count") { post guide_access_path, params: {email_address: "lea@example.org"} }
    assert_enqueued_emails 1
  end

  test "an invalid email is refused" do
    assert_no_difference("GuideReader.count") { post guide_access_path, params: {email_address: "nope"} }
    assert_equal "Cette adresse email n'est pas valide.", flash[:alert]
  end

  test "the emailed link gives access to the guide" do
    reader = GuideReader.create!(email_address: "lea@example.org")

    get guide_access_link_path(reader.generate_token_for(:access))
    assert_redirected_to guide_path
    assert reader.reload.last_accessed_at

    get guide_path
    assert_select "a[href=?]", guide_page_path(@page)

    get guide_page_path(@page)
    assert_response :success
    assert_match "Contenu réservé", response.body
    assert_select ".guide-content img[src=?]", guide_image_path(42)
  end

  test "an expired link doesn't give access" do
    reader = GuideReader.create!(email_address: "lea@example.org")
    token = reader.generate_token_for(:access)

    travel GuideReader::ACCESS_LINK_VALIDITY + 1.minute do
      get guide_access_link_path(token)
    end

    assert_redirected_to guide_path
    assert_match "expiré", flash[:alert]
    get guide_page_path(@page)
    assert_redirected_to guide_path(page: "identifier-le-bon-espace")
  end

  test "signed-in users can read the guide" do
    sign_in_as users(:approved)

    get guide_page_path(@page)

    assert_response :success
  end
end
