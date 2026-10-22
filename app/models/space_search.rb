# Filters the public space directory from the index page's query parameters:
# by care home, then by location: around a point (a chosen commune or "autour
# de moi"), by department, or by free text.
class SpaceSearch
  EARTH_RADIUS_KM = 6371.0
  DEFAULT_RADIUS_KM = "20"

  attr_reader :care_home, :location, :department, :near_mode, :radius_km, :near_lat, :near_lon
  # Why results are degraded, if they are: :places_unavailable or :invalid_radius.
  attr_reader :warning

  def initialize(params)
    @care_home = params[:care_home].to_s.strip
    @location = params[:location].to_s.strip
    @department = params[:department].to_s.strip
    @near_mode = params[:near_mode].to_s.strip
    @radius_km = params[:radius_km].to_s.strip.presence || DEFAULT_RADIUS_KM
    @near_lat = params[:near_lat].to_s.strip
    @near_lon = params[:near_lon].to_s.strip
  end

  # Spaces to display. When searching around a point, an array sorted by
  # distance whose spaces respond to #distance_km.
  def results
    @results ||= begin
      spaces = base_scope
      if coordinates?
        filter_by_distance(spaces)
      elsif department.present?
        filter_by_department(spaces)
      elsif location.present?
        filter_by_location(spaces)
      else
        spaces
      end
    end
  end

  def around_me? = coordinates? && near_mode == "around_me" && radius.to_f.positive?

  def coordinates? = !latitude.nil? && !longitude.nil?

  def radius_label = format("%g", radius)

  private

  def base_scope
    spaces = Space.listed.includes(:recurring_availabilities, images: {image_attachment: {blob: {variant_records: {image_attachment: :blob}}}}, care_home: :address_details)
    care_home.present? ? spaces.where(care_home_id: care_home) : spaces
  end

  # Matches the typed text against care home addresses; when nothing matches,
  # searches around the commune of that name ("Bordeaux", "paris 11e").
  def filter_by_location(spaces)
    matches = spaces.merge(address_matching(location))
    return matches if matches.exists?

    begin
      commune = Places.find_commune(location)
    rescue Places::Error
      @warning = :places_unavailable
      return matches
    end
    return matches if commune.nil?

    @latitude = commune[:latitude]
    @longitude = commune[:longitude]
    filter_by_distance(spaces)
  end

  def address_matching(term)
    normalized = Address.normalize_for_search(term)
    care_homes = CareHome.left_joins(:address_details)
    matching_care_homes = care_homes.where("care_homes.address ILIKE ?", "%#{CareHome.sanitize_sql_like(term)}%")
    matching_care_homes = matching_care_homes.or(care_homes.where("addresses.search_text LIKE ?", "%#{CareHome.sanitize_sql_like(normalized)}%")) if normalized.present?
    Space.where(care_home_id: matching_care_homes.select(:id))
  end

  def filter_by_department(spaces)
    care_homes = CareHome.joins(:address_details).where(addresses: {department_code: department})
    spaces.where(care_home_id: care_homes.select(:id))
  end

  def filter_by_distance(spaces)
    if radius.nil? || radius <= 0
      @warning = :invalid_radius
      return spaces
    end

    spaces.filter_map do |space|
      details = space.care_home.address_details
      next unless details&.coordinates?

      distance = distance_km(latitude, longitude, details.latitude, details.longitude)
      next if distance > radius

      space.distance_km = distance
      space
    end.sort_by(&:distance_km)
  end

  def latitude = @latitude || Float(near_lat, exception: false)

  def longitude = @longitude || Float(near_lon, exception: false)

  def radius = Float(radius_km, exception: false)

  # Haversine formula.
  def distance_km(lat1, lon1, lat2, lon2)
    to_rad = Math::PI / 180
    delta_lat = (lat2 - lat1) * to_rad
    delta_lon = (lon2 - lon1) * to_rad
    a = Math.sin(delta_lat / 2)**2 + Math.cos(lat1 * to_rad) * Math.cos(lat2 * to_rad) * Math.sin(delta_lon / 2)**2
    2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a))
  end
end
