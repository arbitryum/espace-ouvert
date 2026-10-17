# One-off import of the data of the Django prototype (SQLite database and its
# media/ folder). Record ids are kept, so /spaces/:id URLs stay the same.
# Imported users get a random password: set a new one from the console or the admin.
#
#   bin/rails django:import DJANGO_DB=path/to/db.sqlite3 DJANGO_MEDIA=path/to/media
namespace :django do
  desc "Import the Django prototype's SQLite data into an empty database"
  task import: :environment do
    require "sqlite3"

    django = SQLite3::Database.new(ENV.fetch("DJANGO_DB"), readonly: true, results_as_hash: true)
    media = Pathname(ENV.fetch("DJANGO_MEDIA"))
    rows = ->(table) { django.execute("SELECT * FROM #{table} ORDER BY id") }
    utc = ->(value) { value && Time.find_zone("UTC").parse(value) }
    abort "The database already has care homes or users: import into an empty database." if CareHome.exists? || User.exists?

    ActiveRecord::Base.transaction do
      rows.("auth_user").each do |row|
        User.create!(id: row["id"], username: row["username"], email_address: row["email"].presence || "#{row['username']}@example.invalid",
          admin: row["is_superuser"] == 1 || row["is_staff"] == 1, password: SecureRandom.base58(24), created_at: utc.(row["date_joined"]))
      end

      rows.("accounts_ehpadprofile").each do |row|
        EhpadProfile.create!(row.slice("id", "user_id", "establishment_name", "establishment_address", "contact_name", "status")
          .merge(participates_in_spaces: row["participates_in_spaces"] == 1, participates_in_coworking: row["participates_in_coworking"] == 1,
                 created_at: utc.(row["created_at"]), updated_at: utc.(row["updated_at"])))
      end

      rows.("spaces_address").each do |row|
        Address.create!(row.except("created_at", "updated_at").merge(created_at: utc.(row["created_at"]), updated_at: utc.(row["updated_at"])))
      end

      rows.("spaces_carehome").each do |row|
        CareHome.create!(row.slice("id", "name", "address", "legal_status", "contact_name", "contact_email", "group_name")
          .merge(address_details_id: row["address_details_id"]))
      end

      rows.("spaces_nonprofitorganization").each { |row| NonprofitOrganization.create!(row.slice("id", "name", "address")) }

      rows.("spaces_space").each do |row|
        Space.create!(row.slice("id", "care_home_id", "name", "availability", "description", "status", "publication_status")
          .merge(published_at: utc.(row["pub_date"])))
      end

      rows.("spaces_spaceimage").each do |row|
        path = media.join(row["image"])
        unless path.exist?
          puts "  ⚠ missing #{path}, image #{row['id']} skipped"
          next
        end
        SpaceImage.create!(id: row["id"], space_id: row["space_id"], alt_text: row["alt_text"], position: row["order"],
          created_at: utc.(row["created_at"]), image: { io: path.open, filename: path.basename.to_s })
      end

      rows.("spaces_recurringavailability").each do |row|
        RecurringAvailability.create!(row.slice("id", "space_id", "weekday", "start_time", "end_time", "notes").merge(active: row["is_active"] == 1))
      end

      rows.("coworking_coworkingproject").each do |row|
        CoworkingProject.create!(row.slice("id", "name", "organization_name", "description", "location", "care_home_id", "status")
          .merge(published: row["is_published"] == 1, created_at: utc.(row["created_at"]), updated_at: utc.(row["updated_at"])))
      end
    end

    %w[users ehpad_profiles addresses care_homes nonprofit_organizations spaces space_images recurring_availabilities coworking_projects]
      .each { |table| ActiveRecord::Base.connection.reset_pk_sequence!(table) }

    puts "Imported #{User.count} users, #{CareHome.count} care homes, #{Address.count} addresses, #{Space.count} spaces, " \
         "#{SpaceImage.count} images, #{RecurringAvailability.count} slots, #{CoworkingProject.count} coworking projects."
    puts "Users have a random password; set one with: bin/rails runner 'User.find_by!(username: \"…\").update!(password: \"…\")'"
  end
end
