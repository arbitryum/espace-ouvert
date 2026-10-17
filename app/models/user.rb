class User < ApplicationRecord
  PASSWORD_RESET_VALIDITY = 1.hour

  # The reset token also stops working once the password has changed.
  has_secure_password reset_token: {expires_in: PASSWORD_RESET_VALIDITY}
  has_many :sessions, dependent: :destroy
  has_one :ehpad_profile, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, length: {minimum: 8}, format: {without: /\A\d+\z/, message: "ne doit pas être uniquement numérique"},
    allow_nil: true

  # Admins sign in directly; establishments need their profile to be approved.
  def can_sign_in?
    admin? || ehpad_profile&.approved?
  end

  def to_s = email_address
end
