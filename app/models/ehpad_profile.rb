class EhpadProfile < ApplicationRecord
  STATUS_LABELS = {
    "pending" => "En attente de validation",
    "approved" => "Validé",
    "suspended" => "Suspendu"
  }.freeze

  belongs_to :user

  enum :status, STATUS_LABELS.keys.index_by(&:itself), default: "pending"

  validates :establishment_name, :establishment_address, :contact_name, presence: true

  def status_label = STATUS_LABELS.fetch(status)

  def to_s = establishment_name
end
