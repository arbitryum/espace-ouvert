class CoworkingProjectResource < Madmin::Resource
  attribute :id, form: false
  attribute :name, index: true
  attribute :organization_name, index: true
  attribute :location, index: true
  attribute :status, :select, collection: CoworkingProject.human_enum_options(:status), index: true
  attribute :published, index: true
  attribute :care_home
  attribute :description
  attribute :created_at, form: false

  def self.display_name(record) = record.to_s
end
