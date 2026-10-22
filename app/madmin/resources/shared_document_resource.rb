class SharedDocumentResource < Madmin::Resource
  # Shown, when published, at the bottom of the association directory (/spaces).
  attribute :id, form: false
  attribute :title, index: true
  attribute :published, index: true
  attribute :position, index: true
  attribute :description, :text
  attribute :file
  attribute :updated_at, form: false

  def self.default_sort_column = "position"
  def self.default_sort_direction = "asc"

  def self.display_name(record) = record.to_s
end
