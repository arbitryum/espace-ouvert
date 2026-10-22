# A visitor's request to be hosted by a care home, for association activities
# or coworking, each with its own questions. The care home answers it from its
# account (pending until then). Requests sent before the questions split keep
# a free-text message and schedule.
class HostingRequest < ApplicationRecord
  NEEDS = %w[wifi storage parking lunch other].freeze
  WEEKDAYS = (0..4).to_a.freeze

  belongs_to :care_home
  belongs_to :space, optional: true

  enum :kind, %w[association coworking].index_by(&:itself), default: "association"
  enum :status, %w[pending accepted refused].index_by(&:itself), default: "pending"
  enum :compensation, %w[moderate_rent time both].index_by(&:itself), validate: {allow_nil: true}

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :weekdays, with: ->(days) { days.compact_blank.map(&:to_i).uniq.sort }
  normalizes :needs, :slots, with: ->(values) { values.compact_blank.uniq }

  before_validation :drop_other_kind_answers, :set_contact_name

  validates :organization_name, :contact_name, :email, presence: true
  validates :organization_name, :contact_name, :email, :first_name, :last_name, :website, :needs_other, length: {maximum: 200}
  validates :activity, length: {maximum: 300}
  validates :phone, length: {maximum: 30}
  validates :message, :schedule, :refusal_reason, :activity_type, :contribution, length: {maximum: 5000}
  validates :extra, length: {maximum: 500}
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validate :space_of_the_care_home

  # The current form; older requests only had a name and a message.
  with_options on: :create do
    validates :first_name, :last_name, :activity, presence: true

    with_options if: :coworking? do
      validates :team_size, numericality: {only_integer: true, in: 1..50}
      validates :days_per_week, numericality: {only_integer: true, in: 1..5}
      validates :compensation, presence: true
      validate :days_chosen
    end

    with_options if: :association? do
      validates :activity_type, presence: true
      validates :attendees, numericality: {only_integer: true, in: 1..500}
      # Checked when sent only: the care home may change its slots later.
      validate :slots_of_the_care_home
    end
  end
  validate :known_choices

  # The requests of the care homes an establishment account manages, pending first.
  scope :for_profile, ->(profile) { where(care_home: profile.care_homes).in_order_of(:status, %w[pending accepted refused]).order(created_at: :desc) }

  def accept! = update!(status: "accepted", answered_at: Time.current)

  def refuse!(reason) = update!(status: "refused", refusal_reason: reason.to_s.strip, answered_at: Time.current)

  def greeting_name = first_name.presence || contact_name

  def to_s = "#{organization_name} → #{care_home}"

  private

  # The form disables the other kind's fields; this also covers crafted requests.
  def drop_other_kind_answers
    if coworking?
      self.space = nil
      self.activity_type = ""
      self.attendees = nil
      self.slots = []
      self.contribution = ""
    else
      self.website = ""
      self.team_size = self.days_per_week = self.compensation = nil
      self.weekdays = []
      self.flexible_days = false
      self.needs = []
      self.needs_other = ""
    end
  end

  def set_contact_name
    full_name = [first_name, last_name].compact_blank.join(" ")
    self.contact_name = full_name if full_name.present?
  end

  def days_chosen
    errors.add(:weekdays, :blank) if weekdays.empty? && !flexible_days?
  end

  def known_choices
    errors.add(:weekdays, :inclusion) unless (weekdays - WEEKDAYS).empty?
    errors.add(:needs, :inclusion) unless (needs - NEEDS).empty?
  end

  def slots_of_the_care_home
    errors.add(:slots, :inclusion) unless (slots - care_home.slot_choices.map(&:last)).empty?
  end

  def space_of_the_care_home
    errors.add(:space, :other_care_home) if space && space.care_home_id != care_home_id
  end
end
