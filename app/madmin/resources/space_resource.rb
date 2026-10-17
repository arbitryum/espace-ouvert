class SpaceResource < Madmin::Resource
  attribute :id, form: false
  attribute :name, index: true
  attribute :care_home, index: true
  attribute :status, :select, collection: Space.human_enum_options(:status), index: true
  attribute :publication_status, :select, collection: Space.human_enum_options(:publication_status), index: true
  attribute :published_at, index: true
  attribute :description
  attribute :availability
  attribute :images, :nested_has_many, skip: %i[space]
  attribute :recurring_availabilities, :nested_has_many, skip: %i[space]

  scope :draft
  scope :published
  scope :archived

  def self.default_sort_column = "published_at"
  def self.default_sort_direction = "desc"

  def self.display_name(record) = record.to_s
end
