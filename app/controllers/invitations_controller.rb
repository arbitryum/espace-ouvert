# The link emailed to an invited admin, to choose their password.
class InvitationsController < ApplicationController
  before_action :set_user_by_token

  def edit
  end

  def update
    # has_secure_password ignores a blank password instead of rejecting it.
    @user.errors.add(:password, :blank) if params[:password].blank?

    if @user.errors.none? && @user.update(params.permit(:password, :password_confirmation))
      start_new_session_for @user
      redirect_to madmin_root_path, notice: t(".notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:invitation, params[:token])
    redirect_to new_session_path, alert: t("invitations.invalid_link") unless @user
  end
end
