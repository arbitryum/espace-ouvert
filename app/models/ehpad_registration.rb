# Sign-up form for an establishment: creates the account of its project
# referent (who receives the requests), its pending profile, and its care home
# with the coworking space and association spaces it offers. The account can
# sign in, and the spaces are published, once an admin approves the profile.
class EhpadRegistration
  include ActiveModel::Model
  include ActiveModel::Attributes

  MODULES = %w[coworking spaces].freeze
  PHOTO_TYPES = %w[image/jpeg image/png image/webp image/heic image/heif].freeze
  MAX_PHOTOS = 6
  MAX_PHOTO_SIZE = 15.megabytes

  attribute :establishment_name, :string
  attribute :legal_status, :string
  attribute :group_name, :string
  attribute :street, :string
  attribute :postal_code, :string
  attribute :city, :string
  attribute :contact_name, :string
  attribute :email_address, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :modules, default: -> { [] }
  # "yes" or "no": a closed space for a small coworking team.
  attribute :coworking_space, :string
  attribute :coworking_photos, default: -> { [] }

  validates :establishment_name, :legal_status, :street, :postal_code, :city, :contact_name, presence: true
  validates :establishment_name, :group_name, :contact_name, :city, length: {maximum: 200}
  validates :street, length: {maximum: 255}
  validates :legal_status, inclusion: {in: CareHome::LEGAL_STATUSES}, allow_blank: true
  validates :postal_code, format: {with: /\A\d{5}\z/}, allow_blank: true
  validate :at_least_one_module, :coworking_answer, :spaces_described
  validate { photo_errors(coworking_photos).each { |error| errors.add(:coworking_photos, error) } }

  def modules=(values)
    super(Array(values).compact_blank & MODULES)
  end

  def coworking_photos=(files)
    super(Array(files).compact_blank)
  end

  def coworking? = modules.include?("coworking")

  def spaces? = modules.include?("spaces")

  # Association spaces, from the form's numbered blocks.
  def spaces
    @spaces ||= []
  end

  def spaces=(values)
    rows = values.respond_to?(:values) ? values.to_h.values : Array(values)
    @spaces = rows.map { |row| SpaceInput.new(row.to_h.symbolize_keys.slice(:name, :description, :photos, :slots)) }
  end

  def establishment_address = "#{street.to_s.strip}, #{postal_code.to_s.strip} #{city.to_s.strip}"

  def save
    form_valid = valid?
    user_valid = user.valid?
    user.errors.each { |error| errors.add(error.attribute, error.message) }
    return false unless form_valid && user_valid

    care_home = User.transaction { create_records }
    geocode(care_home)
    true
  end

  # Checks uploaded photos: count, type and size. Returns error symbols.
  def photo_errors(files)
    errors = []
    errors << :too_many_photos if files.size > MAX_PHOTOS
    errors << :photo_type if files.any? { |file| !PHOTO_TYPES.include?(file.content_type) }
    errors << :photo_size if files.any? { |file| file.size > MAX_PHOTO_SIZE }
    errors
  end

  # One association space as entered in the form, with a start and end time
  # for each day it's open.
  class SpaceInput
    include ActiveModel::Model
    include ActiveModel::Attributes

    TIME = /\A([01]\d|2[0-3]):[0-5]\d\z/

    attribute :name, :string
    attribute :description, :string
    attribute :photos, default: -> { [] }

    validates :name, :description, presence: true
    validates :name, length: {maximum: 200}
    validates :description, length: {maximum: 5000}
    validate :slot_times

    def photos=(files)
      super(Array(files).compact_blank)
    end

    # {weekday => {enabled:, start_time:, end_time:}}, weekday 0 = Monday.
    def slots
      @slots ||= (0..6).to_h { |day| [day, {enabled: false, start_time: "", end_time: ""}] }
    end

    def slots=(rows)
      rows = rows.respond_to?(:to_h) ? rows.to_h : {}
      @slots = (0..6).to_h do |day|
        row = rows[day.to_s] || rows[day] || {}
        [day, {enabled: row["enabled"] == "1", start_time: row["start_time"].to_s, end_time: row["end_time"].to_s}]
      end
    end

    def availabilities
      slots.select { |_, slot| slot[:enabled] }.map { |day, slot| {weekday: day, start_time: slot[:start_time], end_time: slot[:end_time]} }
    end

    private

    def slot_times
      availabilities.each do |slot|
        valid = slot[:start_time].match?(TIME) && slot[:end_time].match?(TIME) && slot[:start_time] < slot[:end_time]
        errors.add(:slots, :invalid_times, day: RecurringAvailability.weekday_name(slot[:weekday]).downcase) unless valid
      end
    end
  end

  private

  def user
    @user ||= User.new(email_address:, password:, password_confirmation:)
  end

  def create_records
    user.save!
    profile = user.create_ehpad_profile!(establishment_name:, establishment_address:, contact_name:,
      participates_in_spaces: spaces?, participates_in_coworking: coworking?)
    care_home = CareHome.create!(name: establishment_name, address: establishment_address, legal_status:,
      group_name: group_name.to_s, contact_name:, contact_email: user.email_address, ehpad_profile: profile,
      offers_coworking: coworking?, coworking_photos: coworking? ? coworking_photos : [])
    spaces.each { |input| create_space(care_home, input) } if spaces?
    care_home
  end

  # A draft until the profile is approved (see EhpadProfile#publish_draft_spaces).
  def create_space(care_home, input)
    care_home.spaces.create!(name: input.name, description: input.description, publication_status: "draft",
      published_at: Time.current, recurring_availabilities_attributes: input.availabilities,
      images_attributes: input.photos.each_with_index.map { |file, position| {image: file, position:, alt_text: input.name} })
  end

  # For the maps; the back office can geocode again if the service fails.
  def geocode(care_home)
    care_home.refresh_address_details!
  rescue Geocoder::Error => error
    Rails.logger.warn("[EhpadRegistration] Geocoding #{care_home.address} failed: #{error.message}")
  end

  def at_least_one_module
    errors.add(:modules, :none_selected) if modules.empty?
  end

  def coworking_answer
    return unless coworking?

    if coworking_space.blank?
      errors.add(:coworking_space, :blank)
    elsif coworking_space == "no"
      errors.add(:coworking_space, :needed_for_coworking)
    end
  end

  def spaces_described
    return unless spaces?

    errors.add(:spaces, :none) if spaces.empty?
    spaces.each_with_index do |input, index|
      input.validate
      photo_errors(input.photos).each { |error| input.errors.add(:photos, error) }
      errors.add(:spaces, :invalid, number: index + 1) if input.errors.any?
    end
  end
end
