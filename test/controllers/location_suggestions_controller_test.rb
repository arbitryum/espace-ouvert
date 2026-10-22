require "test_helper"

class LocationSuggestionsControllerTest < ActionDispatch::IntegrationTest
  test "returns place suggestions" do
    suggestion = {kind: "city", label: "Paris (75)", context: "Paris", latitude: 48.8566, longitude: 2.3522}
    queries = []

    Places.stub(:suggest, ->(query) {
      queries << query
      [suggestion]
    }) do
      get location_suggestions_spaces_path(q: "par")
    end

    assert_response :success
    assert_equal "Paris (75)", response.parsed_body["results"].first["label"]
    assert_equal ["par"], queries
  end

  test "short query returns nothing without calling the places service" do
    Places.stub(:suggest, ->(_) { flunk "places service called" }) do
      get location_suggestions_spaces_path(q: "p")
    end

    assert_response :success
    assert_equal [], response.parsed_body["results"]
  end
end
