class SpaceImage < ApplicationRecord
  belongs_to :space
  has_one_attached :image

  validates :image, presence: true

  def to_s = "#{space.name} - Image #{position}"
end
