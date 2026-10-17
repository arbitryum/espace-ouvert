class GuideReaderResource < Madmin::Resource
  # People who asked for the coworking guide by email.
  attribute :id, form: false
  attribute :email_address, index: true
  attribute :created_at, form: false, index: true
  attribute :last_accessed_at, form: false, index: true

  def self.default_sort_column = "created_at"

  def self.default_sort_direction = "desc"

  def self.display_name(record) = record.to_s
end
