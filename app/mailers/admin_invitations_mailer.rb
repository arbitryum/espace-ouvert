class AdminInvitationsMailer < ApplicationMailer
  def invitation(user)
    @url = edit_invitation_url(user.generate_token_for(:invitation))
    @validity = User::INVITATION_VALIDITY.in_days.to_i
    mail to: user.email_address
  end
end
