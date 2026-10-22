# A visitor's request to be hosted by a care home, for association activities
# or coworking. The care home answers it from its account (pending until then).
class HostingRequest < ApplicationRecord
  belongs_to :care_home
  belongs_to :space, optional: true

  enum :kind, %w[association coworking].index_by(&:itself), default: "association"
  enum :status, %w[pending accepted refused].index_by(&:itself), default: "pending"

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :organization_name, :contact_name, :email, :message, presence: true
  validates :organization_name, :contact_name, :email, length: {maximum: 200}
  validates :phone, length: {maximum: 30}
  validates :message, :schedule, length: {maximum: 5000}
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validate :space_of_the_care_home

  def to_s = "#{organization_name} → #{care_home}"

  private

  def space_of_the_care_home
    errors.add(:space, :other_care_home) if space && space.care_home_id != care_home_id
  end
end
