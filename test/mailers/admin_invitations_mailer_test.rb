require "test_helper"

class AdminInvitationsMailerTest < ActionMailer::TestCase
  test "invitation" do
    user = users(:admin)

    mail = AdminInvitationsMailer.invitation(user)

    assert_equal ["admin@example.com"], mail.to
    token = mail.text_part.decoded[%r{/comptes/invitation/(\S+)/accepter}, 1]
    assert_equal user, User.find_by_token_for(:invitation, token)
    assert_match "7 jours", mail.text_part.decoded
  end
end
