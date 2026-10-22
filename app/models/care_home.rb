class CareHome < ApplicationRecord
  LEGAL_STATUSES = %w[associatif public prive].freeze

  belongs_to :address_details, class_name: "Address", optional: true, inverse_of: :care_homes
  # The establishment account that manages it, linked in the back office.
  belongs_to :ehpad_profile, optional: true
  has_many :spaces, dependent: :destroy
  has_many :coworking_projects, dependent: :nullify
  has_many :hosting_requests, dependent: :destroy
  # Photos of the space offered to a coworking team (registration form).
  has_many_attached :coworking_photos

  validates :name, :address, presence: true
  validates :legal_status, inclusion: {in: LEGAL_STATUSES}, allow_blank: true

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

  # The weekly slots of its listed spaces, as [space id, label] for the request
  # form, which keeps the label.
  def slot_choices
    spaces.listed.includes(:recurring_availabilities).flat_map do |space|
      space.recurring_availabilities.select(&:active?).map do |slot|
        [space.id, "#{space.name} – #{slot.weekday_name} #{slot.time_range}"]
      end
    end
  end

  # Who receives its hosting requests: its approved account, otherwise its
  # contact email, otherwise the admins.
  def request_recipients
    account_email = ehpad_profile.user.email_address if ehpad_profile&.approved?
    Array(account_email.presence || contact_email.presence || User.where(admin: true).pluck(:email_address))
  end

  def to_s = name
end
