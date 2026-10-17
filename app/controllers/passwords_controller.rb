# "Mot de passe oublié": emails a link to choose a new password.
class PasswordsController < ApplicationController
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Réessayez plus tard." }

  def new
  end

  # Same answer whether the email has an account or not, so the form doesn't
  # tell who is registered.
  def create
    if (user = User.find_by(email_address: params[:email_address].to_s.strip.downcase))
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to new_session_path, notice: "Si un compte existe pour cette adresse, vous allez recevoir un email pour choisir un nouveau mot de passe."
  end

  def edit
  end

  def update
    # has_secure_password ignores a blank password instead of rejecting it.
    @user.errors.add(:password, :blank) if params[:password].blank?

    if @user.errors.none? && @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Votre mot de passe a été modifié. Vous pouvez vous connecter."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "Ce lien n'est plus valable. Demandez-en un nouveau."
  end
end
