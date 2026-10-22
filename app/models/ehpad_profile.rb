class EhpadProfile < ApplicationRecord
  belongs_to :user
  has_many :care_homes, dependent: :nullify

  enum :status, %w[pending approved suspended].index_by(&:itself), default: "pending"

  validates :establishment_name, :establishment_address, :contact_name, presence: true

  # Spaces entered at registration wait for this approval to be published.
  after_update_commit :publish_draft_spaces, if: -> { saved_change_to_status?(to: "approved") }

  def to_s = establishment_name

  private

  def publish_draft_spaces
    Space.draft.where(care_home: care_homes).find_each do |space|
      space.update!(publication_status: "published", published_at: Time.current)
    end
  end
end
