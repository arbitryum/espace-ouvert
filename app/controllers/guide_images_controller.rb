# Serves the guide's images to readers only, through short-lived storage URLs,
# so the image addresses can't be shared outside the guide.
class GuideImagesController < ApplicationController
  include GuideAccess
  include ActiveStorage::SetCurrent

  URL_VALIDITY = 5.minutes

  def show
    raise ActiveRecord::RecordNotFound unless guide_access?

    attachment = ActiveStorage::Attachment.find_by!(id: params[:id], record_type: "GuidePage")
    variant = attachment.variant(resize_to_limit: [1600, 1600], format: :webp, saver: {quality: 80, strip: true})
    expires_in URL_VALIDITY, public: false
    redirect_to variant.processed.url(expires_in: URL_VALIDITY), allow_other_host: true
  end
end
