require "net/http"

# French communes and departments from the government's API Découpage
# administratif, for the location box of the space filters. Unlike Nominatim,
# it completes prefixes ("par" → Paris) and stays in France.
# https://geo.api.gouv.fr/decoupage-administratif
module Places
  class Error < StandardError; end

  ENDPOINT = URI("https://geo.api.gouv.fr")
  COMMUNE_FIELDS = "nom,codesPostaux,centre,codeDepartement,departement"
  POSTAL_CODE = /\A\d{5}\z/
  DEPARTMENT_CODE = /\A(?:\d{2,3}|2[ab])\z/i

  extend self

  # Departments, then communes by population. Never raises so the search box
  # keeps working.
  def suggest(query, limit: 6)
    query = query.to_s.strip
    return [] if query.length < 2

    departments = departments_matching(query).first(2)
    departments + communes_matching(query, limit: limit - departments.size)
  rescue Error => error
    Rails.logger.error("[Places] #{error.message}")
    []
  end

  # The most populated commune matching the query, or nil.
  def find_commune(query)
    query = query.to_s.strip
    communes_matching(query, limit: 1).first if query.length >= 2
  end

  private

  def departments_matching(query)
    return [] if query.match?(POSTAL_CODE)

    params = query.match?(DEPARTMENT_CODE) ? {code: query.upcase} : {nom: query, limit: 2}
    get("/departements", **params).map do |department|
      {kind: "department", label: "#{department["nom"]} (#{department["code"]})", department_code: department["code"]}
    end
  end

  def communes_matching(query, limit:)
    return [] if limit <= 0 || query.match?(DEPARTMENT_CODE)

    params = query.match?(POSTAL_CODE) ? {codePostal: query} : {nom: query, boost: "population"}
    get("/communes", **params, fields: COMMUNE_FIELDS, limit:).filter_map do |commune|
      longitude, latitude = commune.dig("centre", "coordinates")
      next if latitude.nil?

      {
        kind: "city",
        label: "#{commune["nom"]} (#{commune["codeDepartement"]})",
        context: commune.dig("departement", "nom"),
        latitude:,
        longitude:
      }
    end
  end

  def get(path, **params)
    uri = ENDPOINT.dup
    uri.path = path
    uri.query = URI.encode_www_form(params)
    timeout = ENV.fetch("PLACES_TIMEOUT_SECONDS", 3).to_i

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
      http.get(uri.request_uri)
    end
    raise Error, "Places service error: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => error
    raise Error, "Places service error: #{error.message}"
  end
end
