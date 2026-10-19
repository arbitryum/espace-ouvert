# Invites an admin by email: creates the account with a random password
# nobody knows, and emails a link to choose one. Inviting an admin again
# sends a new link, which is how an expired invitation gets renewed.
class AdminInvitation
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email_address, :string

  validate :user_valid
  validate :not_an_establishment

  def save
    return false unless valid?

    user.save!
    AdminInvitationsMailer.invitation(user).deliver_later
    true
  end

  def user
    @user ||= User.find_or_initialize_by(email_address:).tap do |user|
      if user.new_record?
        user.admin = true
        user.password = SecureRandom.base58(32)
      end
    end
  end

  private

  def user_valid
    user.validate
    user.errors.each { |error| errors.add(error.attribute, error.message) }
  end

  # Turning an establishment's account into an admin is done by editing the
  # user, not by sending an invitation.
  def not_an_establishment
    errors.add(:email_address, :not_an_admin) if user.persisted? && !user.admin?
  end
end
