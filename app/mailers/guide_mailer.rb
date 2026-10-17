class GuideMailer < ApplicationMailer
  def access_link(reader)
    @url = guide_access_link_url(reader.generate_token_for(:access))
    @validity = GuideReader::ACCESS_LINK_VALIDITY.in_days.to_i
    mail to: reader.email_address
  end
end
