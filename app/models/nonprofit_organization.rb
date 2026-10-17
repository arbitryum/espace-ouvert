class NonprofitOrganization < ApplicationRecord
  validates :name, :address, presence: true

  def to_s = name
end
