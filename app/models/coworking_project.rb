class CoworkingProject < ApplicationRecord
  STATUS_LABELS = {
    "draft" => "Brouillon",
    "seeking" => "Recherche d'un établissement",
    "matched" => "Projet mis en relation",
    "active" => "Accueil en cours",
    "closed" => "Terminé"
  }.freeze

  belongs_to :care_home, optional: true

  enum :status, STATUS_LABELS.keys.index_by(&:itself), default: "draft"

  validates :name, :organization_name, :description, :location, presence: true

  scope :visible, -> { where(published: true).order(created_at: :desc) }

  def status_label = STATUS_LABELS.fetch(status)

  def to_s = name
end
