class SpaceImageResource < Madmin::Resource
  attribute :id, form: false
  attribute :space, index: true
  attribute :image
  attribute :alt_text, index: true
  attribute :position, index: true

  def self.display_name(record) = record.to_s
end
