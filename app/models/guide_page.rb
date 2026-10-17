# A page of the coworking guide. Only readers with access can see it
# (see GuideAccess): its images are served through GuideImagesController.
class GuidePage < ApplicationRecord
  # Marks an image in `body` with its attachment id; replaced by its URL when rendering.
  IMAGE_PLACEHOLDER = /data-guide-image="(\d+)"/

  has_one_attached :cover
  has_many_attached :images

  validates :section, :title, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(:section_position, :position) }

  def self.sections = ordered.group_by(&:section)

  def to_param = slug

  def to_s = title
end
