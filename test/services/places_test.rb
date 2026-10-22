require "test_helper"

class PlacesTest < ActiveSupport::TestCase
  PERREUX = {
    "nom" => "Le Perreux-sur-Marne", "codeDepartement" => "94",
    "centre" => {"type" => "Point", "coordinates" => [2.5045, 48.8433]},
    "departement" => {"code" => "94", "nom" => "Val-de-Marne"}
  }.freeze
  VAL_DE_MARNE = {"nom" => "Val-de-Marne", "code" => "94"}.freeze

  def stub_api(responses, &)
    requests = []
    get = ->(path, **params) {
      requests << [path, params.except(:fields)]
      responses.fetch(path)
    }
    Places.stub(:get, get, &)
    requests
  end

  test "suggests departments then communes by population" do
    results = nil
    requests = stub_api("/departements" => [VAL_DE_MARNE], "/communes" => [PERREUX]) { results = Places.suggest("val") }

    assert_equal [
      {kind: "department", label: "Val-de-Marne (94)", department_code: "94"},
      {kind: "city", label: "Le Perreux-sur-Marne (94)", context: "Val-de-Marne", latitude: 48.8433, longitude: 2.5045}
    ], results
    assert_equal [["/departements", {nom: "val", limit: 2}], ["/communes", {nom: "val", boost: "population", limit: 5}]], requests
  end

  test "a department code only looks up that department" do
    requests = stub_api("/departements" => [VAL_DE_MARNE]) { Places.suggest("94") }

    assert_equal [["/departements", {code: "94"}]], requests
  end

  test "a postal code only looks up its communes" do
    requests = stub_api("/communes" => [PERREUX]) { Places.suggest("94170") }

    assert_equal [["/communes", {codePostal: "94170", limit: 6}]], requests
  end

  test "suggest swallows service errors" do
    assert_equal [], Places.stub(:get, ->(*, **) { raise Places::Error, "down" }) { Places.suggest("paris") }
  end

  test "find commune returns the best match" do
    commune = nil
    stub_api("/communes" => [PERREUX]) { commune = Places.find_commune("perreux") }

    assert_equal "Le Perreux-sur-Marne (94)", commune[:label]
    assert_equal 48.8433, commune[:latitude]
  end
end
