require "test_helper"

class CareHomeTest < ActiveSupport::TestCase
  GEOCODED = {
    label: "9 Rue Maria Helena Vieira da Silva 75014 Paris", city: "Paris", postal_code: "75014", city_code: "75114",
    department_code: "75", department_name: "Paris", region_name: "Île-de-France", latitude: 48.8301, longitude: 2.3202,
    ban_id: "75114_0009", ban_score: 0.97
  }.freeze

  test "refresh address details creates a normalized address" do
    care_home = create_care_home(name: "Alice Prin", address: "9 Rue Maria Helena Vieira da Silva,  75014 Paris")
    queries = []
    geocode = ->(query) {
      queries << query
      GEOCODED
    }

    result = Geocoder.stub(:geocode, geocode) { care_home.refresh_address_details! }

    assert_not_nil result
    details = care_home.reload.address_details
    assert_equal "9 Rue Maria Helena Vieira da Silva, 75014 Paris", details.label
    assert_equal "Paris", details.city
    assert_equal "75", details.department_code
    assert_equal 48.8301, details.latitude
    assert_equal ["9 Rue Maria Helena Vieira da Silva, 75014 Paris"], queries
  end

  test "refresh address details keeps the care home unchanged when nothing is found" do
    care_home = create_care_home

    assert_nil Geocoder.stub(:geocode, nil) { care_home.refresh_address_details! }
    assert_nil care_home.reload.address_details
  end
end
