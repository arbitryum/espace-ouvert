# Sign-up form for an establishment: creates the user account and its
# pending EHPAD profile together. The account can sign in once an admin
# approves the profile.
class EhpadRegistration
  include ActiveModel::Model
  include ActiveModel::Attributes

  MODULES = %w[spaces coworking].freeze

  attribute :establishment_name, :string
  attribute :establishment_address, :string
  attribute :contact_name, :string
  attribute :email_address, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :modules, default: -> { [] }

  validates :establishment_name, :establishment_address, :contact_name, presence: true
  validates :establishment_name, :contact_name, length: {maximum: 200}
  validates :establishment_address, length: {maximum: 255}
  validate :at_least_one_module

  def modules=(values)
    super(Array(values).compact_blank & MODULES)
  end

  def save
    form_valid = valid?
    user_valid = user.valid?
    user.errors.each { |error| errors.add(error.attribute, error.message) }
    return false unless form_valid && user_valid

    User.transaction do
      user.save!
      user.create_ehpad_profile!(
        establishment_name:, establishment_address:, contact_name:,
        participates_in_spaces: modules.include?("spaces"),
        participates_in_coworking: modules.include?("coworking")
      )
    end
    true
  end

  private

  def user
    @user ||= User.new(email_address:, password:, password_confirmation:)
  end

  def at_least_one_module
    errors.add(:modules, :none_selected) if modules.empty?
  end
end
