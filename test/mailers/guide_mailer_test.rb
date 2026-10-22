require "test_helper"

class GuideMailerTest < ActionMailer::TestCase
  test "access link" do
    reader = GuideReader.create!(email_address: "lea@example.org")

    mail = GuideMailer.access_link(reader)

    assert_equal ["lea@example.org"], mail.to
    assert_equal "Votre accès au guide du coworking en EHPAD", mail.subject
    token = mail.text_part.decoded[%r{/coworking/guide/acces/(\S+)}, 1]
    assert_equal reader, GuideReader.find_by_token_for(:access, token)
  end

  test "the link leads to the page the reader opened" do
    reader = GuideReader.create!(email_address: "lea@example.org")
    page = GuidePage.create!(section: "Introduction", title: "Identifier le bon espace", slug: "identifier-le-bon-espace", body: "<p>x</p>")

    mail = GuideMailer.access_link(reader, page:)

    assert_match %r{/coworking/guide/acces/\S+\?page=identifier-le-bon-espace}, mail.text_part.decoded
  end
end
