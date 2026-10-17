class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Label of an enum value, from activerecord.enums.<model>.<attribute>.<value>
  def self.human_enum_name(attribute, value) = I18n.t("activerecord.enums.#{model_name.i18n_key}.#{attribute}.#{value}")

  # [label, value] pairs, for select inputs.
  def self.human_enum_options(attribute) = public_send(attribute.to_s.pluralize).keys.map { [human_enum_name(attribute, it), it] }

  def human_enum_name(attribute) = self.class.human_enum_name(attribute, public_send(attribute))
end
