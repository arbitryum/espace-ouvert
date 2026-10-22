class Space < ApplicationRecord
  belongs_to :care_home
  has_many :images, -> { order(:position, :created_at) }, class_name: "SpaceImage", dependent: :destroy
  has_many :recurring_availabilities, -> { order(:weekday, :start_time) }, dependent: :destroy
  accepts_nested_attributes_for :images, :recurring_availabilities, allow_destroy: true

  enum :status, %w[available full limited].index_by(&:itself), default: "available"
  enum :publication_status, %w[draft published archived].index_by(&:itself), default: "published"

  validates :name, :published_at, presence: true

  # Set by SpaceSearch when searching around a point.
  attribute :distance_km, :float

  scope :already_published, -> { published.where(published_at: ..Time.current) }
  # What visitors see in the directory: full spaces too, tagged and last.
  scope :listed, -> { already_published.in_order_of(:status, %w[available full]).order(published_at: :desc) }
  # Listed spaces that can host someone now.
  scope :open, -> { listed.available }

  def public? = published? && !full?

  def published_recently?
    published_at.between?(1.day.ago, Time.current)
  end

  def to_s = "#{name} (#{care_home.name})"
end
