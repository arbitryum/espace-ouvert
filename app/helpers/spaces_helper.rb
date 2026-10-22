module SpacesHelper
  RADIUS_OPTIONS_KM = %w[2 5 10 20 50].freeze

  # Data for the Leaflet map: one marker per space whose care home is geocoded.
  def spaces_map_markers(spaces)
    spaces.filter_map do |space|
      details = space.care_home.address_details
      next unless details&.coordinates?

      first_image = space.images.first
      {
        id: space.id,
        name: space.name,
        care_home_name: space.care_home.name,
        address: details.concise_label.presence || space.care_home.address,
        availability: space.availability,
        distance_km: space.distance_km,
        image_url: first_image ? url_for(first_image.image.variant(:card)) : "",
        image_alt: first_image&.alt_text.to_s,
        detail_url: space_path(space),
        latitude: details.latitude,
        longitude: details.longitude
      }
    end
  end

  def view_mode_url(mode)
    url_for(request.query_parameters.merge(view_mode: mode))
  end
end
