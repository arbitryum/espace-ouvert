# A document offered to associations on the directory page (hosting
# agreement, living-together guide…), managed in the back office.
class SharedDocument < ApplicationRecord
  CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.oasis.opendocument.text
  ].freeze
  MAX_SIZE = 20.megabytes

  has_one_attached :file

  validates :title, presence: true, length: {maximum: 200}
  validates :description, length: {maximum: 1000}
  validates :file, presence: true
  validate :file_kind

  scope :visible, -> { where(published: true).with_attached_file.order(:position, :title) }

  def to_s = title

  private

  def file_kind
    return unless file.attached?

    errors.add(:file, :content_type) unless CONTENT_TYPES.include?(file.blob.content_type)
    errors.add(:file, :too_large) if file.blob.byte_size > MAX_SIZE
  end
end
