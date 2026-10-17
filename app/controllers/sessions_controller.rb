class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limited") }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    if user.nil?
      @error = t(".invalid_credentials")
    elsif !user.can_sign_in?
      @error = t(".pending_approval")
    end

    if @error
      render :new, status: :unprocessable_content
    else
      start_new_session_for user
      redirect_to after_authentication_url
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
