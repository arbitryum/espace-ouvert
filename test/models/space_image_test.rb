require "test_helper"

class SpaceImageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def create_image
    create_space(name: "Photo space").images.create!(image: {io: file_fixture("photo.jpg").open, filename: "photo.jpg"})
  end

  test "processes the variants that page URLs resolve to" do
    space_image = create_image
    url = Rails.application.routes.url_helpers.rails_representation_path(space_image.image.variant(:card), only_path: true)
    variation_key = url.split("/")[-2]

    # What ActiveStorage::Representations::RedirectController looks up for that URL.
    requested = space_image.image.blob.representation(variation_key)

    assert_equal requested.variation.digest, space_image.page_variant(:card).variation.digest
  end

  test "creating an image enqueues its variants" do
    assert_enqueued_with(job: SpaceImageVariantsJob) { create_image }
  end
end
