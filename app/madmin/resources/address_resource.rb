class AddressResource < Madmin::Resource
  attribute :id, form: false
  attribute :raw_address, index: true
  attribute :label
  attribute :city, index: true
  attribute :postal_code, index: true
  attribute :department_code, index: true
  attribute :department_name
  attribute :region_name, index: true
  attribute :latitude, index: true
  attribute :longitude, index: true
  attribute :ban_score
  attribute :care_homes, form: false

  def self.display_name(record) = record.to_s
end
