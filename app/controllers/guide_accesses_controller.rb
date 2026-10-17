class GuideAccessesController < ApplicationController
  include GuideAccess

  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to guide_path, alert: t("guide_accesses.create.rate_limited") }

  # Saves the email and sends the access link.
  def create
    reader = GuideReader.find_or_initialize_by(email_address: params.expect(:email_address))
    if reader.save
      GuideMailer.access_link(reader).deliver_later
      redirect_to guide_path, notice: t(".notice", email: reader.email_address)
    else
      redirect_to guide_path, alert: t(".invalid_email")
    end
  end

  # The emailed link.
  def show
    if (reader = GuideReader.find_by_token_for(:access, params[:token]))
      grant_guide_access(reader)
      redirect_to guide_path
    else
      redirect_to guide_path, alert: t(".expired")
    end
  end
end
