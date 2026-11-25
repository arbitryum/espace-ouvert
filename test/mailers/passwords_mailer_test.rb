require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:approved)

    mail = PasswordsMailer.reset(user)

    assert_equal ["approved@example.com"], mail.to
    token = mail.text_part.decoded[%r{/comptes/mot-de-passe/(\S+)/nouveau}, 1]
    assert_equal user, User.find_by_password_reset_token(token)
    assert_match "60 minutes", mail.text_part.decoded

    # Mail clients show the HTML part: it must carry the link too.
    html = mail.html_part.decoded
    assert_includes html, "/comptes/mot-de-passe/#{token}/nouveau"
    assert_match "Choisir un nouveau mot de passe", html
    assert_match "60 minutes", html
    assert_match "Espace-Ouvert by Arbitryum", html
  end
end
