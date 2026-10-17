class SpaceImage < ApplicationRecord
  VARIANTS = %i[card large].freeze

  belongs_to :space

  # Uploads are full-size phone photos (4032×3024, ~3 MB): pages show these
  # resized WebP versions instead.
  has_one_attached :image do |attachable|
    attachable.variant :card, resize_to_limit: [800, 600], format: :webp, saver: {quality: 80, strip: true}
    attachable.variant :large, resize_to_limit: [1600, 1200], format: :webp, saver: {quality: 80, strip: true}
  end

  validates :image, presence: true

  after_create_commit -> { SpaceImageVariantsJob.perform_later(self) }

  # Generates the resized versions now, so visitors don't wait for them.
  def process_variants!
    VARIANTS.each { |name| page_variant(name).processed }
  end

  # The variant as pages request it, through the variation key in its URL.
  # Rails gives the in-memory transformations a different digest than the same
  # ones decoded from a URL (symbol vs string keys), so processing
  # `image.variant(name)` directly (or `preprocessed: true`) creates copies
  # that pages never use.
  def page_variant(name)
    image.blob.representation(image.variant(name).variation.key)
  end

  def to_s = "#{space.name} ##{position}"
end
