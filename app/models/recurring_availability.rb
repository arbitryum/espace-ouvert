class RecurringAvailability < ApplicationRecord
  belongs_to :space

  validates :weekday, inclusion: {in: 0..6}
  validates :start_time, :end_time, presence: true

  scope :active, -> { where(active: true) }

  # weekday: 0 = Monday … 6 = Sunday, while I18n's day names start on Sunday.
  def self.weekday_name(weekday) = I18n.t("date.day_names").rotate(1).fetch(weekday).capitalize

  def weekday_name = self.class.weekday_name(weekday)

  def time_range = "#{start_time.strftime("%H:%M")} – #{end_time.strftime("%H:%M")}"

  def to_s = "#{space.name} - #{weekday_name}"
end
