class GuideAccessesController < ApplicationController
  include GuideAccess

  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to guide_path, alert: t("guide_accesses.create.rate_limited") }

  # Saves the email and sends the access link, to the requested page if any.
  def create
    reader = GuideReader.find_or_initialize_by(email_address: params.expect(:email_address))
    page = GuidePage.find_by(slug: params[:page])
    if reader.save
      GuideMailer.access_link(reader, page:).deliver_later
      redirect_to guide_path, notice: t(".notice", email: reader.email_address)
    else
      redirect_to guide_path, alert: t(".invalid_email")
    end
  end

  # The emailed link; ?page= is looked up, so it can only lead to a guide page.
  def show
    reader = GuideReader.find_by_token_for(:access, params[:token])
    if reader
      grant_guide_access(reader)
      page = GuidePage.find_by(slug: params[:page])
      redirect_to page ? guide_page_path(page) : guide_path
    else
      redirect_to guide_path, alert: t(".expired")
    end
  end
end
