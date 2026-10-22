class CareHomeResource < Madmin::Resource
  # Saving a new or changed address geocodes it (see Madmin::CareHomesController).
  attribute :id, form: false
  attribute :name, index: true
  attribute :address, index: true
  attribute :address_details, form: false, index: true
  attribute :legal_status, :select, collection: [["", ""], *CareHome::LEGAL_STATUSES.map { [CareHome.human_enum_name(:legal_status, it), it] }]
  attribute :contact_name
  attribute :contact_email
  attribute :group_name
  # The account that receives its hosting requests.
  attribute :ehpad_profile
  # In the coworking directory (has a closed space for a small team).
  attribute :offers_coworking, index: true
  # Tagged "Complet" in the coworking directory.
  attribute :coworking_full
  attribute :coworking_photos
  attribute :spaces, form: false
  attribute :coworking_projects, form: false
  attribute :hosting_requests, form: false

  def self.default_sort_column = "name"
  def self.default_sort_direction = "asc"

  def self.display_name(record) = record.to_s
end
