class SpaceImage < ApplicationRecord
  belongs_to :space

  # Uploads are full-size phone photos (4032×3024, ~3 MB): pages show these
  # resized WebP versions instead, generated in the background after upload.
  has_one_attached :image do |attachable|
    attachable.variant :card, resize_to_limit: [ 800, 600 ], format: :webp, quality: 80, strip: true, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1600, 1200 ], format: :webp, quality: 80, strip: true, preprocessed: true
  end

  validates :image, presence: true

  def to_s = "#{space.name} - Image #{position}"
end
