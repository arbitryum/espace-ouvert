class CareHomeResource < Madmin::Resource
  # Saving a new or changed address geocodes it (see Madmin::CareHomesController).
  attribute :id, form: false
  attribute :name, index: true
  attribute :address, index: true
  attribute :address_details, form: false, index: true
  attribute :legal_status, :select, collection: [ [ "", "" ], *CareHome::LEGAL_STATUSES.invert.to_a ]
  attribute :contact_name
  attribute :contact_email
  attribute :group_name
  attribute :spaces, form: false
  attribute :coworking_projects, form: false

  def self.default_sort_column = "name"
  def self.default_sort_direction = "asc"

  def self.display_name(record) = record.to_s
end
