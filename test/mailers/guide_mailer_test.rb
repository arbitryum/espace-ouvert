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
end
