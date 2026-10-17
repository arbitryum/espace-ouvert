require "net/http"

# Thin client for the OpenStreetMap Nominatim search API.
# https://nominatim.org/release-docs/latest/api/Search/
module Geocoder
  class Error < StandardError; end

  ENDPOINT = URI("https://nominatim.openstreetmap.org/search")
  USER_AGENT = "espaces-ouverts/1.0"

  extend self

  # Returns the attributes of an Address for the best match, or nil.
  def geocode(query)
    return if query.blank?

    place = search(query, limit: 1).first
    if place.nil?
      Rails.logger.warn("[Geocoder] No result for #{query}")
      return
    end

    address_components(place).merge(raw_address: query)
  end

  # Search terms (full labels and their comma-separated parts) for a free-text location, or nil.
  def resolve_terms(query, limit: 10)
    return if query.blank?

    places = search(query, limit:)
    return if places.empty?

    places.flat_map { |place| [ place["display_name"], *place["display_name"].split(",") ] }
      .map(&:strip).compact_blank.uniq.sort
  end

  # Autocomplete suggestions; never raises so the search box keeps working.
  def suggest(query, limit: 6)
    return [] if query.blank?

    search(query, limit:).map do |place|
      {
        label: place["display_name"],
        name: place["display_name"].split(",").first,
        latitude: place["lat"].to_f,
        longitude: place["lon"].to_f
      }
    end
  rescue Error => error
    Rails.logger.error("[Geocoder] #{error.message}")
    []
  end

  private
    def search(query, limit:)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(q: query, format: "jsonv2", addressdetails: 1, limit:)
      timeout = ENV.fetch("GEOCODING_TIMEOUT_SECONDS", 10).to_i

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
        http.get(uri.request_uri, "User-Agent" => USER_AGENT, "Accept-Language" => "fr")
      end
      raise Error, "Geocoding service error: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => error
      raise Error, "Geocoding service error: #{error.message}"
    end

    def address_components(place)
      address = place.fetch("address", {})
      postal_code = address["postcode"].to_s
      iso_codes = address.select { |key, _| key.start_with?("ISO3166-2-lvl") }.values.join(" ")

      {
        label: place["display_name"],
        latitude: place["lat"].to_f,
        longitude: place["lon"].to_f,
        city: address.values_at("city", "town", "village", "municipality").compact.first.to_s,
        postal_code: postal_code,
        department_code: iso_codes[/(?:FR-)?(\d{2}|2A|2B)\b/, 1] || postal_code.first(2),
        department_name: address["county"].to_s.sub(/\A(Département|Department) de\s+/, ""),
        region_name: address["state"].to_s
      }
    end
end
