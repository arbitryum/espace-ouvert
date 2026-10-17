class RecurringAvailabilityResource < Madmin::Resource
  attribute :id, form: false
  attribute :space, index: true
  attribute :weekday, :select, collection: (0..6).map { [RecurringAvailability.weekday_name(it), it] }, index: true
  attribute :start_time, index: true
  attribute :end_time, index: true
  attribute :notes
  attribute :active, index: true

  def self.display_name(record) = record.to_s
end
