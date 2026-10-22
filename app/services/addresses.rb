require "net/http"

# French addresses from IGN's Géoplateforme geocoding service (the Base Adresse
# Nationale), for the address field of the registration form. Unlike
# Nominatim, it allows autocomplete and splits street, postal code and city.
# https://geoservices.ign.fr/documentation/services/services-geoplateforme/geocodage
module Addresses
  class Error < StandardError; end

  ENDPOINT = URI("https://data.geopf.fr/geocodage/search")
  # Results that make a street line; municipalities alone don't.
  TYPES = %w[housenumber street locality].freeze
  # The service rejects shorter queries.
  MIN_LENGTH = 3

  extend self

  # Never raises so the form keeps working without suggestions.
  def suggest(query, limit: 5)
    query = query.to_s.strip
    return [] if query.length < MIN_LENGTH

    search(q: query, index: "address", autocomplete: 1, limit:).filter_map do |feature|
      address = feature["properties"]
      next unless TYPES.include?(address["type"])

      {
        label: address["label"],
        street: address["name"],
        postal_code: address["postcode"],
        city: address["city"],
        context: address["context"]
      }
    end
  rescue Error => error
    Rails.logger.error("[Addresses] #{error.message}")
    []
  end

  private

  def search(**params)
    uri = ENDPOINT.dup
    uri.query = URI.encode_www_form(params)
    timeout = ENV.fetch("ADDRESSES_TIMEOUT_SECONDS", 3).to_i

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
      http.get(uri.request_uri)
    end
    raise Error, "Addresses service error: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("features", [])
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => error
    raise Error, "Addresses service error: #{error.message}"
  end
end
