class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :ehpad_profile, dependent: :destroy

  normalizes :username, with: ->(username) { username.strip }
  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 150 },
    format: { with: /\A[\w.@+-]+\z/, message: "ne peut contenir que des lettres, chiffres et @/./+/-/_" }
  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, format: { without: /\A\d+\z/, message: "ne doit pas être uniquement numérique" },
    allow_nil: true

  # Admins sign in directly; establishments need their profile to be approved.
  def can_sign_in?
    admin? || ehpad_profile&.approved?
  end

  def to_s = username
end
