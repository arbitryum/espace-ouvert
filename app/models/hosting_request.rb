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
  validates :message, :schedule, :refusal_reason, length: {maximum: 5000}
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validate :space_of_the_care_home

  # The requests of the care homes an establishment account manages, pending first.
  scope :for_profile, ->(profile) { where(care_home: profile.care_homes).in_order_of(:status, %w[pending accepted refused]).order(created_at: :desc) }

  def accept! = update!(status: "accepted", answered_at: Time.current)

  def refuse!(reason) = update!(status: "refused", refusal_reason: reason.to_s.strip, answered_at: Time.current)

  def to_s = "#{organization_name} → #{care_home}"

  private

  def space_of_the_care_home
    errors.add(:space, :other_care_home) if space && space.care_home_id != care_home_id
  end
end
