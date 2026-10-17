namespace :seed do
  desc "Replace care homes and spaces with lib/seeds/spaces.yml (photos from SEED_IMAGES_DIR)"
  task spaces: :environment do
    Seeds::Spaces.run
  end

  desc "Create or update sample coworking projects"
  task coworking: :environment do
    Seeds::Coworking.run
  end

  desc "Add weekly availability slots to sample spaces"
  task availability: :environment do
    Seeds::Availability.run
  end
end

namespace :geocode do
  desc "Geocode care homes without coordinates (FORCE=1 to redo all of them)"
  task care_homes: :environment do
    care_homes = ENV["FORCE"] ? CareHome.all : CareHome.where(address_details_id: nil)
    care_homes.order(:name).each do |care_home|
      details = care_home.refresh_address_details!
      puts details ? "  ✓ #{care_home.name}: #{details.city} (#{details.department_code}) [#{details.latitude}, #{details.longitude}]" : "  ? #{care_home.name}: no match"
    rescue Geocoder::Error => error
      puts "  ✗ #{care_home.name}: #{error.message}"
    end
  end
end
