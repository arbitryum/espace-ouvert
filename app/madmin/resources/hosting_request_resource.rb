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
  attribute :contact_name
  attribute :email
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
