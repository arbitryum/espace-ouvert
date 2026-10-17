# Loads the sample data: `bin/rails db:seed`.
# Each part can also run on its own: bin/rails seed:spaces, seed:coworking, seed:availability.
#
# Seeds::Spaces deletes every care home and space first. Space photos are read
# from SEED_IMAGES_DIR (default tmp/seed_images), which is not versioned.
Seeds::Spaces.run
Seeds::Coworking.run
Seeds::Availability.run
