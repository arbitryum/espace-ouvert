class NonprofitOrganizationResource < Madmin::Resource
  attribute :id, form: false
  attribute :name, index: true
  attribute :address, index: true

  def self.display_name(record) = record.to_s
end
