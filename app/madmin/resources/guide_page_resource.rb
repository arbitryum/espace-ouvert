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

  # GuidePage#to_param is the slug, so admin links carry it instead of the id.
  def self.model_find(slug) = model.find_by!(slug:)

  def self.display_name(record) = record.to_s
end
