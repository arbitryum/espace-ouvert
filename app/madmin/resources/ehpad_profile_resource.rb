class EhpadProfileResource < Madmin::Resource
  # Approving a profile lets its user sign in.
  attribute :id, form: false
  attribute :establishment_name, index: true
  attribute :contact_name, index: true
  attribute :user, form: false
  attribute :status, :select, collection: EhpadProfile.human_enum_options(:status), index: true
  attribute :participates_in_spaces, index: true
  attribute :participates_in_coworking, index: true
  attribute :establishment_address
  attribute :care_homes, form: false
  attribute :created_at, form: false

  scope :pending
  scope :approved
  scope :suspended

  def self.default_sort_column = "created_at"
  def self.default_sort_direction = "desc"

  def self.display_name(record) = record.to_s
end
