require "test_helper"

class SpaceSearchTest < ActiveSupport::TestCase
  def search(**params) = SpaceSearch.new(params).results.to_a

  def space_at(name, care_home_address: "Adresse", **address_attributes)
    care_home = create_care_home(name: "Maison #{name}", address: care_home_address)
    care_home.update!(address_details: create_address(**address_attributes)) if address_attributes.any?
    create_space(name:, care_home:, availability: "Disponible", description: "Test")
  end

  test "lists published available spaces, newest first" do
    old = create_space(name: "Old", days: -5)
    recent = create_space(name: "Recent", days: -1)
    create_space(name: "Future", days: 5)
    create_space(name: "Draft", publication_status: "draft")
    create_space(name: "Full", status: "full")

    assert_equal [ recent, old ], search
  end

  test "filters by care home" do
    space = create_space(name: "Here")
    create_space(name: "Elsewhere")

    assert_equal [ space ], search(care_home: space.care_home_id.to_s)
  end

  test "filters by location in the care home address" do
    matching = space_at("Paris", care_home_address: "10 rue de Paris, 75010 Paris")
    space_at("Lyon", care_home_address: "5 place Bellecour, 69002 Lyon")

    Geocoder.stub(:resolve_terms, ->(_) { flunk "no geocoding needed" }) do
      assert_equal [ matching ], search(location: "Paris")
    end
  end

  test "filters by department code in the care home address" do
    matching = space_at("94", care_home_address: "1 rue X, 94170 Le Perreux-sur-Marne")
    space_at("75", care_home_address: "1 rue Y, 75012 Paris")

    assert_equal [ matching ], search(location: "94170")
  end

  test "filters by normalized city, department and region" do
    matching = space_at("Ville", city: "Saint-Étienne", department_code: "42", department_name: "Loire", region_name: "Auvergne-Rhône-Alpes")
    space_at("Autre", city: "Paris", department_code: "75", department_name: "Paris", region_name: "Île-de-France")

    assert_equal [ matching ], search(location: "saint etienne")
    assert_equal [ matching ], search(location: "Loire")
    assert_equal [ matching ], search(location: "auvergne rhone")
  end

  test "falls back on geocoded terms when nothing matches locally" do
    matching = space_at("IDF", city: "Paris", region_name: "Île-de-France")
    space_at("Lyon", city: "Lyon", region_name: "Auvergne-Rhône-Alpes")
    queries = []

    results = Geocoder.stub(:resolve_terms, ->(query) { queries << query; [ "Île-de-France" ] }) { search(location: "idf") }

    assert_equal [ matching ], results
    assert_equal [ "idf" ], queries
  end

  test "keeps local results and warns when the geocoder is down" do
    space_at("Paris", city: "Paris")
    search = SpaceSearch.new(location: "idf")

    Geocoder.stub(:resolve_terms, ->(_) { raise Geocoder::Error, "down" }) do
      assert_empty search.results
    end
    assert_match "indisponible", search.warning
  end

  test "filters around me within the radius, sorted by distance" do
    nearby = space_at("Proche", latitude: 48.8566, longitude: 2.3522)
    space_at("Loin", latitude: 45.7640, longitude: 4.8357)

    search = SpaceSearch.new(near_lat: "48.8566", near_lon: "2.3522", radius_km: "5", near_mode: "around_me")

    assert_equal [ nearby ], search.results
    assert search.around_me?
    assert_equal "5", search.radius_label
    assert_in_delta 0.0, search.results.first.distance_km, 0.0001
  end

  test "ignores an invalid radius" do
    space = space_at("Proche", latitude: 48.8566, longitude: 2.3522)
    search = SpaceSearch.new(near_lat: "48.8566", near_lon: "2.3522", radius_km: "-1", near_mode: "around_me")

    assert_equal [ space ], search.results.to_a
    assert_not search.around_me?
    assert_equal "Rayon invalide pour la recherche autour de moi.", search.warning
  end
end
