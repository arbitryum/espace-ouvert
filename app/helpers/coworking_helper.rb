module CoworkingHelper
  # Markers of the directory map: one per project whose care home is geocoded.
  # Projects only have a free-text location otherwise, which isn't geocoded.
  def coworking_project_markers(projects)
    projects.filter_map do |project|
      details = project.care_home&.address_details
      next unless details&.coordinates?

      {
        id: project.id,
        title: project.name,
        subtitle: project.organization_name,
        address: details.concise_label.presence || project.care_home.address,
        text: truncate(project.description, length: 160),
        latitude: details.latitude,
        longitude: details.longitude
      }
    end
  end
end
