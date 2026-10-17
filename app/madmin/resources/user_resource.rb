class UserResource < Madmin::Resource
  attribute :id, form: false
  attribute :email_address, index: true
  attribute :admin, index: true
  attribute :ehpad_profile, form: false, index: true
  attribute :password, show: false
  attribute :password_confirmation, show: false
  attribute :created_at, form: false

  def self.display_name(record) = record.to_s
end
