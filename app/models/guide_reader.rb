# Someone who asked for the coworking guide. They get access through the link
# emailed to them, which signs them in as a reader with a cookie.
class GuideReader < ApplicationRecord
  ACCESS_LINK_VALIDITY = 7.days

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}

  generates_token_for :access, expires_in: ACCESS_LINK_VALIDITY

  def to_s = email_address
end
