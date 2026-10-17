require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:approved)

    mail = PasswordsMailer.reset(user)

    assert_equal ["approved@example.com"], mail.to
    token = mail.text_part.decoded[%r{/comptes/mot-de-passe/(\S+)/nouveau}, 1]
    assert_equal user, User.find_by_password_reset_token(token)
    assert_match "60 minutes", mail.text_part.decoded
  end
end
