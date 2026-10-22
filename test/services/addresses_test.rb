require "test_helper"

class AddressesTest < ActiveSupport::TestCase
  def feature(**properties)
    {"type" => "Feature", "properties" => properties.transform_keys(&:to_s)}
  end

  HOUSE = {
    type: "housenumber", label: "12 Rue de la Paix 75002 Paris", name: "12 Rue de la Paix",
    postcode: "75002", city: "Paris", context: "75, Paris, Île-de-France"
  }.freeze

  test "suggests addresses split into street, postal code and city" do
    requests = []
    results = Addresses.stub(:search, ->(**params) {
      requests << params
      [feature(**HOUSE)]
    }) { Addresses.suggest(" 12 rue de la paix ") }

    assert_equal [{
      label: "12 Rue de la Paix 75002 Paris", street: "12 Rue de la Paix",
      postal_code: "75002", city: "Paris", context: "75, Paris, Île-de-France"
    }], results
    assert_equal [{q: "12 rue de la paix", index: "address", autocomplete: 1, limit: 5}], requests
  end

  test "leaves out municipalities, which have no street" do
    municipality = feature(type: "municipality", label: "Paris", name: "Paris", postcode: "75001", city: "Paris")
    results = Addresses.stub(:search, ->(**) { [municipality, feature(**HOUSE)] }) { Addresses.suggest("paris") }

    assert_equal ["12 Rue de la Paix"], results.pluck(:street)
  end

  test "short queries don't call the service" do
    assert_equal [], Addresses.stub(:search, ->(**) { flunk "service called" }) { Addresses.suggest("12") }
  end

  test "suggest swallows service errors" do
    assert_equal [], Addresses.stub(:search, ->(**) { raise Addresses::Error, "down" }) { Addresses.suggest("rue de la paix") }
  end
end
