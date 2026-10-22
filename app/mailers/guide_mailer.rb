class GuideMailer < ApplicationMailer
  # page: the guide page the reader wanted to open, if any.
  def access_link(reader, page: nil)
    @url = guide_access_link_url(reader.generate_token_for(:access), page: page&.slug)
    @validity = GuideReader::ACCESS_LINK_VALIDITY.in_days.to_i
    mail to: reader.email_address
  end
end
