# A document offered to associations on the directory page (hosting
# agreement, living-together charter…), managed in the back office: either an
# uploaded file or a link, to a shared Google document for instance.
class SharedDocument < ApplicationRecord
  CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.oasis.opendocument.text
  ].freeze
  MAX_SIZE = 20.megabytes

  has_one_attached :file

  normalizes :url, with: ->(url) { url.strip }

  validates :title, presence: true, length: {maximum: 200}
  validates :description, length: {maximum: 1000}
  validates :url, length: {maximum: 2000}
  validate :file_or_link, :file_kind, :web_link

  scope :visible, -> { where(published: true).with_attached_file.order(:position, :title) }

  def link? = url.present?

  # The site the link points to, shown next to it ("docs.google.com").
  def link_host = URI.parse(url).host

  def to_s = title

  private

  def file_or_link
    if !file.attached? && url.blank?
      errors.add(:base, :file_or_link)
    elsif file.attached? && url.present?
      errors.add(:base, :not_both)
    end
  end

  def file_kind
    return unless file.attached?

    errors.add(:file, :content_type) unless CONTENT_TYPES.include?(file.blob.content_type)
    errors.add(:file, :too_large) if file.blob.byte_size > MAX_SIZE
  end

  # Only web links: the page puts it in an href.
  def web_link
    return if url.blank?

    uri = URI.parse(url)
    errors.add(:url, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end
end
