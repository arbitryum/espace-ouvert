class RecurringAvailability < ApplicationRecord
  # 0 = Monday … 6 = Sunday (unlike Ruby's Date#wday, which starts on Sunday).
  WEEKDAYS = %w[Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche].freeze

  belongs_to :space

  validates :weekday, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true

  scope :active, -> { where(active: true) }

  def weekday_name = WEEKDAYS.fetch(weekday)

  def time_range = "#{start_time.strftime('%H:%M')} – #{end_time.strftime('%H:%M')}"

  def to_s = "#{space.name} - #{weekday_name}"
end
