class SpaceImageVariantsJob < ApplicationJob
  def perform(space_image)
    space_image.process_variants!
  end
end
