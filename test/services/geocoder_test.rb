require "test_helper"

class GeocoderTest < ActiveSupport::TestCase
  PLACE = {
    "display_name" => "Avenue du 8 Mai 1945, 94170 Le Perreux-sur-Marne, France",
    "lat" => "48.846", "lon" => "2.507",
    "address" => {
      "road" => "Avenue du 8 Mai 1945", "postcode" => "94170", "town" => "Le Perreux-sur-Marne",
      "county" => "Val-de-Marne", "state" => "Île-de-France", "ISO3166-2-lvl6" => "FR-94"
    }
  }.freeze

  test "geocode extracts structured address components" do
    queries = []
    search = ->(query, limit:) {
      queries << [query, limit]
      [PLACE]
    }

    result = Geocoder.stub(:search, search) { Geocoder.geocode("117 Av. du 8 Mai 1945, 94170 Le Perreux-sur-Marne") }

    assert_equal "Le Perreux-sur-Marne", result[:city]
    assert_equal "94170", result[:postal_code]
    assert_equal "94", result[:department_code]
    assert_equal "Val-de-Marne", result[:department_name]
    assert_equal "Île-de-France", result[:region_name]
    assert_equal 48.846, result[:latitude]
    assert_equal [["117 Av. du 8 Mai 1945, 94170 Le Perreux-sur-Marne", 1]], queries
  end

  test "geocode returns nil when nothing is found" do
    assert_nil Geocoder.stub(:search, ->(*, **) { [] }) { Geocoder.geocode("nowhere") }
  end

  test "resolve terms returns labels and their parts" do
    terms = Geocoder.stub(:search, ->(*, **) { [PLACE] }) { Geocoder.resolve_terms("perreux") }

    assert_includes terms, "94170 Le Perreux-sur-Marne"
    assert_includes terms, PLACE["display_name"]
  end

  test "suggest swallows service errors" do
    assert_equal [], Geocoder.stub(:search, ->(*, **) { raise Geocoder::Error, "down" }) { Geocoder.suggest("paris") }
  end
end
