class HostingRequestResource < Madmin::Resource
  # Sent by visitors from a care home's page, and answered by the care home:
  # read-only here.
  attribute :id
  attribute :organization_name, index: true
  attribute :care_home, index: true
  attribute :kind, :select, collection: HostingRequest.human_enum_options(:kind), index: true
  attribute :status, :select, collection: HostingRequest.human_enum_options(:status), index: true
  attribute :created_at, index: true
  attribute :space
  attribute :first_name
  attribute :last_name
  attribute :email
  attribute :activity
  attribute :website
  attribute :team_size
  attribute :days_per_week
  attribute :weekdays
  attribute :flexible_days
  attribute :needs
  attribute :needs_other
  attribute :compensation
  attribute :activity_type
  attribute :attendees
  attribute :slots
  attribute :contribution
  attribute :extra
  # Requests sent before the questions split.
  attribute :contact_name
  attribute :phone
  attribute :message
  attribute :schedule
  attribute :answered_at
  attribute :refusal_reason

  scope :pending
  scope :accepted
  scope :refused

  def self.default_sort_column = "created_at"
  def self.default_sort_direction = "desc"

  def self.readonly? = true

  def self.display_name(record) = record.to_s
end
