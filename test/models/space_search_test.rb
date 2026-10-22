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

    assert_equal [recent, old], search
  end

  test "filters by care home" do
    space = create_space(name: "Here")
    create_space(name: "Elsewhere")

    assert_equal [space], search(care_home: space.care_home_id.to_s)
  end

  test "filters by location in the care home address" do
    matching = space_at("Paris", care_home_address: "10 rue de Paris, 75010 Paris")
    space_at("Lyon", care_home_address: "5 place Bellecour, 69002 Lyon")

    Places.stub(:find_commune, ->(_) { flunk "no commune lookup needed" }) do
      assert_equal [matching], search(location: "Paris")
    end
  end

  test "filters by department code in the care home address" do
    matching = space_at("94", care_home_address: "1 rue X, 94170 Le Perreux-sur-Marne")
    space_at("75", care_home_address: "1 rue Y, 75012 Paris")

    assert_equal [matching], search(location: "94170")
  end

  test "filters by normalized city, department and region" do
    matching = space_at("Ville", city: "Saint-Étienne", department_code: "42", department_name: "Loire", region_name: "Auvergne-Rhône-Alpes")
    space_at("Autre", city: "Paris", department_code: "75", department_name: "Paris", region_name: "Île-de-France")

    assert_equal [matching], search(location: "saint etienne")
    assert_equal [matching], search(location: "Loire")
    assert_equal [matching], search(location: "auvergne rhone")
  end

  test "searches around the commune when nothing matches locally" do
    perreux = space_at("Perreux", latitude: 48.8433, longitude: 2.5045)
    space_at("Lyon", latitude: 45.7640, longitude: 4.8357)
    queries = []

    search = SpaceSearch.new(location: "perreux sur marne", radius_km: "10")
    results = Places.stub(:find_commune, ->(query) {
      queries << query
      {latitude: 48.8433, longitude: 2.5045}
    }) { search.results }

    assert_equal [perreux], results
    assert_equal ["perreux sur marne"], queries
    assert_not search.around_me?
  end

  test "finds nothing when the commune has no space nearby" do
    space_at("Paris", city: "Paris", latitude: 48.8566, longitude: 2.3522)

    results = Places.stub(:find_commune, ->(_) { {latitude: 44.8378, longitude: -0.5792} }) { search(location: "Bordeaux") }

    assert_empty results
  end

  test "finds nothing when the text is no known place" do
    space_at("Paris", city: "Paris", latitude: 48.8566, longitude: 2.3522)

    assert_empty Places.stub(:find_commune, nil) { search(location: "zzz") }
  end

  test "keeps local results and warns when the places service is down" do
    space_at("Paris", city: "Paris")
    search = SpaceSearch.new(location: "idf")

    Places.stub(:find_commune, ->(_) { raise Places::Error, "down" }) do
      assert_empty search.results
    end
    assert_equal :places_unavailable, search.warning
  end

  test "filters by department code" do
    matching = space_at("94", department_code: "94", latitude: 48.84, longitude: 2.50)
    space_at("75", department_code: "75", latitude: 48.85, longitude: 2.35)

    assert_equal [matching], search(department: "94", location: "Val-de-Marne (94)")
  end

  test "filters around me within the radius, sorted by distance" do
    nearby = space_at("Proche", latitude: 48.8566, longitude: 2.3522)
    space_at("Loin", latitude: 45.7640, longitude: 4.8357)

    search = SpaceSearch.new(near_lat: "48.8566", near_lon: "2.3522", radius_km: "5", near_mode: "around_me")

    assert_equal [nearby], search.results
    assert search.around_me?
    assert_equal "5", search.radius_label
    assert_in_delta 0.0, search.results.first.distance_km, 0.0001
  end

  test "ignores an invalid radius" do
    space = space_at("Proche", latitude: 48.8566, longitude: 2.3522)
    search = SpaceSearch.new(near_lat: "48.8566", near_lon: "2.3522", radius_km: "-1", near_mode: "around_me")

    assert_equal [space], search.results.to_a
    assert_not search.around_me?
    assert_equal :invalid_radius, search.warning
  end
end
