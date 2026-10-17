class PasswordsMailer < ApplicationMailer
  def reset(user)
    @url = edit_password_url(user.password_reset_token)
    @validity = User::PASSWORD_RESET_VALIDITY.in_minutes.to_i
    mail to: user.email_address
  end
end
