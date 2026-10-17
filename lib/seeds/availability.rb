module Seeds
  # Adds weekly time slots to the spaces with these names (weekday 0 = Monday).
  class Availability
    SCHEDULES = {
      "Le forum" => [ [ 1, "09:00", "17:00" ], [ 3, "09:00", "17:00" ] ],
      "Bibliothèque" => [ [ 0, "14:00", "18:00" ], [ 4, "09:00", "12:00" ] ],
      "Salle polyvalente" => [ [ 2, "10:00", "16:00" ] ]
    }.freeze

    def self.run(output: $stdout)
      created = 0
      SCHEDULES.each do |space_name, slots|
        Space.where(name: space_name).find_each do |space|
          slots.each do |weekday, start_time, end_time|
            slot = space.recurring_availabilities.find_or_create_by!(weekday:, start_time:, end_time:)
            created += 1 if slot.previously_new_record?
          end
        end
      end
      output.puts "Seeded #{created} recurring availability slots."
    end
  end
end
