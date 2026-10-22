class EhpadProfile < ApplicationRecord
  belongs_to :user
  has_many :care_homes, dependent: :nullify

  enum :status, %w[pending approved suspended].index_by(&:itself), default: "pending"

  validates :establishment_name, :establishment_address, :contact_name, presence: true

  def to_s = establishment_name
end
