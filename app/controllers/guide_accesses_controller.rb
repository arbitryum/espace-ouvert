class GuideAccessesController < ApplicationController
  include GuideAccess

  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to guide_path, alert: "Trop de demandes, réessayez plus tard." }

  # Saves the email and sends the access link.
  def create
    reader = GuideReader.find_or_initialize_by(email_address: params.expect(:email_address))
    if reader.save
      GuideMailer.access_link(reader).deliver_later
      redirect_to guide_path, notice: "C'est envoyé ! Ouvrez le lien reçu par email à #{reader.email_address} pour accéder au guide."
    else
      redirect_to guide_path, alert: "Cette adresse email n'est pas valide."
    end
  end

  # The emailed link.
  def show
    if (reader = GuideReader.find_by_token_for(:access, params[:token]))
      grant_guide_access(reader)
      redirect_to guide_path
    else
      redirect_to guide_path, alert: "Ce lien a expiré. Saisissez à nouveau votre email pour en recevoir un nouveau."
    end
  end
end
