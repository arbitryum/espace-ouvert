class CoworkingProject < ApplicationRecord
  belongs_to :care_home, optional: true

  enum :status, %w[draft seeking matched active closed].index_by(&:itself), default: "draft"

  validates :name, :organization_name, :description, :location, presence: true

  scope :visible, -> { where(published: true).order(created_at: :desc) }

  def to_s = name
end
