require "test_helper"

class AddressSuggestionsControllerTest < ActionDispatch::IntegrationTest
  test "returns address suggestions" do
    suggestion = {label: "12 Rue de la Paix 75002 Paris", street: "12 Rue de la Paix", postal_code: "75002", city: "Paris", context: "75, Paris, Île-de-France"}
    queries = []

    Addresses.stub(:suggest, ->(query) {
      queries << query
      [suggestion]
    }) do
      get address_suggestions_path(q: "12 rue de la paix")
    end

    assert_response :success
    assert_equal "75002", response.parsed_body["results"].first["postal_code"]
    assert_equal ["12 rue de la paix"], queries
  end

  test "a missing query is a bad request" do
    get address_suggestions_path

    assert_response :bad_request
  end
end
