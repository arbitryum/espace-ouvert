class CareHome < ApplicationRecord
  LEGAL_STATUSES = {"associatif" => "Associatif", "public" => "Public", "prive" => "Privé"}.freeze

  belongs_to :address_details, class_name: "Address", optional: true, inverse_of: :care_homes
  has_many :spaces, dependent: :destroy
  has_many :coworking_projects, dependent: :nullify

  validates :name, :address, presence: true
  validates :legal_status, inclusion: {in: LEGAL_STATUSES.keys}, allow_blank: true

  # Geocodes the address and links the matching Address record.
  # Returns nil when the geocoder finds nothing; raises Geocoder::Error when it is unreachable.
  def refresh_address_details!
    normalized_address = address.squish
    if normalized_address.blank?
      update!(address_details: nil)
      return
    end

    result = Geocoder.geocode(normalized_address)
    return if result.nil?

    details = Address.find_or_initialize_by(raw_address: normalized_address)
    details.update!(result.merge(label: normalized_address))
    update!(address: normalized_address, address_details: details)
    details
  end

  def to_s = name
end
