module CoworkingHelper
  # Markers of the directory map: one per geocoded care home.
  def coworking_care_home_markers(care_homes)
    care_homes.filter_map do |care_home|
      details = care_home.address_details
      next unless details&.coordinates?

      photo = care_home.coworking_photos.first
      {
        id: care_home.id,
        title: care_home.name,
        subtitle: care_home.group_name.presence,
        address: details.concise_label.presence || care_home.address,
        image_url: photo ? url_for(photo.variant(:card)) : "",
        image_alt: care_home.name,
        url: care_home_path(care_home),
        full: care_home.coworking_full?,
        tag: coworking_tag(care_home),
        latitude: details.latitude,
        longitude: details.longitude
      }
    end
  end

  # "Complet", or "Accueille déjà une équipe", or nothing.
  def coworking_tag(care_home)
    if care_home.coworking_full?
      t("coworking.care_homes.tags.full")
    elsif care_home.hosting_coworking?
      t("coworking.care_homes.tags.hosting")
    end
  end
end
