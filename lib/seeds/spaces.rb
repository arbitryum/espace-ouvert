module Seeds
  # Replaces every care home and space with those of lib/seeds/spaces.yml,
  # geocoding the care homes and attaching the photos found in SEED_IMAGES_DIR.
  class Spaces
    DATA_FILE = Rails.root.join("lib/seeds/spaces.yml")

    def self.run(images_dir: ENV.fetch("SEED_IMAGES_DIR", Rails.root.join("tmp/seed_images")), output: $stdout)
      new(Pathname(images_dir), output).run
    end

    def initialize(images_dir, output)
      @images_dir = images_dir
      @output = output
      @data = YAML.load_file(DATA_FILE)
    end

    def run
      @output.puts "Clearing existing care homes and spaces..."
      CareHome.destroy_all

      care_homes = @data["care_homes"].to_h { |attributes| [attributes["name"], create_care_home(attributes)] }
      @data["spaces"].each { |attributes| create_space(care_homes.fetch(attributes["care_home"]), attributes) }

      @output.puts "Done: #{CareHome.count} care homes, #{Space.count} spaces, #{SpaceImage.count} images (from #{@images_dir})."
    end

    private

    def create_care_home(attributes)
      care_home = CareHome.create!(attributes)
      care_home.refresh_address_details!
      @output.puts "  ✓ #{care_home.name}"
      care_home
    rescue Geocoder::Error => error
      @output.puts "  ⚠ #{care_home.name} created without coordinates (#{error.message}); retry with bin/rails geocode:care_homes"
      care_home
    end

    def create_space(care_home, attributes)
      space = care_home.spaces.create!(attributes.slice("name", "description", "availability", "status").merge(published_at: Time.current))
      attached = attributes.fetch("images", []).each_with_index.count do |filename, index|
        path = @images_dir.join(filename)
        next false unless path.exist?

        space.images.create!(alt_text: "#{space.name} - Image #{index + 1}", position: index + 1,
          image: {io: path.open, filename:})
      end
      @output.puts "  ✓ #{space} + #{attached}/#{attributes.fetch("images", []).size} image(s)"
    end
  end
end
