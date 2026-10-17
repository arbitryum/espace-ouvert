# A geocoded address, shared by care homes with the same raw address.
class Address < ApplicationRecord
  EMBED_DELTA = 0.01
  POSTAL_CODE_AND_CITY = /\b(\d{5})\s+(.+)\z/
  HOUSE_NUMBER = /\d+(?:\s*[-\/]\s*\d+)?[A-Za-z]?/

  has_many :care_homes, foreign_key: :address_details_id, inverse_of: :address_details, dependent: :nullify

  validates :raw_address, presence: true, uniqueness: true

  before_save :refresh_search_text

  # Lowercase ASCII words only, so "Île-de-France" matches "ile de france".
  def self.normalize_for_search(value)
    ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, " ").squish
  end

  def coordinates? = latitude.present? && longitude.present?

  # "Street, postal code city", built from the address as typed rather than
  # the long Nominatim label ("117, Avenue …, Val-de-Marne, Île-de-France, France").
  def concise_label
    source = raw_address.presence || label
    street = ""
    postal = postal_code
    town = city
    if (match = source.match(POSTAL_CODE_AND_CITY))
      postal = postal.presence || match[1]
      town = town.presence || match[2].strip
      street = source[0...match.begin(0)].strip.delete_suffix(",").strip
    end

    label_parts = label.split(",").map(&:strip).compact_blank
    street = street.presence || label_parts.first || source
    if street.match?(/\A#{HOUSE_NUMBER}\z/o) && label_parts.size > 1
      house_number = source[/\A\s*(#{HOUSE_NUMBER})\b/o, 1] || street
      street = "#{house_number} #{label_parts.second}"
    end

    if street.present? && postal.present? && town.present?
      "#{street}, #{postal} #{town}"
    else
      label.presence || raw_address
    end
  end

  def osm_map_url
    return "" unless coordinates?

    "https://www.openstreetmap.org/?mlat=#{latitude}&mlon=#{longitude}#map=16/#{latitude}/#{longitude}"
  end

  def osm_embed_url
    return "" unless coordinates?

    bbox = [longitude - EMBED_DELTA, latitude - EMBED_DELTA, longitude + EMBED_DELTA, latitude + EMBED_DELTA]
      .map { |value| format("%.6f", value) }.join(",")
    "https://www.openstreetmap.org/export/embed.html?bbox=#{bbox}&layer=mapnik&marker=#{latitude}%2C#{longitude}"
  end

  def to_s = concise_label

  private

  def refresh_search_text
    self.search_text = self.class.normalize_for_search(
      [raw_address, label, city, postal_code, city_code, department_code, department_name, region_name].join(" ")
    )
  end
end
