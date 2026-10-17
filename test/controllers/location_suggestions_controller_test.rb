require "test_helper"

class LocationSuggestionsControllerTest < ActionDispatch::IntegrationTest
  test "returns geocoder suggestions" do
    suggestion = { label: "Paris (75000)", name: "Paris", latitude: 48.8566, longitude: 2.3522 }
    queries = []

    Geocoder.stub(:suggest, ->(query) { queries << query; [ suggestion ] }) do
      get location_suggestions_spaces_path(q: "par")
    end

    assert_response :success
    assert_equal "Paris (75000)", response.parsed_body["results"].first["label"]
    assert_equal [ "par" ], queries
  end

  test "short query returns nothing without calling the geocoder" do
    Geocoder.stub(:suggest, ->(_) { flunk "geocoder called" }) do
      get location_suggestions_spaces_path(q: "p")
    end

    assert_response :success
    assert_equal [], response.parsed_body["results"]
  end
end
