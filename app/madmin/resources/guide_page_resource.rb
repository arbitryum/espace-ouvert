class GuidePageResource < Madmin::Resource
  # Pages of the coworking guide; `body` is HTML imported from Notion.
  attribute :id, form: false
  attribute :section, index: true
  attribute :position, index: true
  attribute :icon, index: true
  attribute :title, index: true
  attribute :slug
  attribute :section_position
  attribute :body, :text
  attribute :cover
  attribute :updated_at, form: false

  def self.default_sort_column = "section_position"

  def self.display_name(record) = record.to_s
end
