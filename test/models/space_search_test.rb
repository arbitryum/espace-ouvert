require "test_helper"

class SpaceSearchTest < ActiveSupport::TestCase
  def search(**params) = SpaceSearch.new(params).results.to_a

  def space_at(name, care_home_address: "Adresse", **address_attributes)
    care_home = create_care_home(name: "Maison #{name}", address: care_home_address)
    care_home.update!(address_details: create_address(**address_attributes)) if address_attributes.any?
    create_space(name:, care_home:, availability: "Disponible", description: "Test")
  end

  test "lists published spaces, newest first, full ones last" do
    old = create_space(name: "Old", days: -5)
    full = create_space(name: "Full", status: "full", days: -1)
    recent = create_space(name: "Recent", days: -2)
    create_space(name: "Future", days: 5)
    create_space(name: "Draft", publication_status: "draft")
    create_space(name: "Limited", status: "limited")

    assert_equal [recent, old, full], search
  end

  test "keeps full spaces last when sorting by distance" do
    full = space_at("Complet proche", latitude: 48.8566, longitude: 2.3522)
    full.update!(status: "full")
    far = space_at("Disponible loin", latitude: 48.90, longitude: 2.40)

    assert_equal [far, full], search(near_lat: "48.8566", near_lon: "2.3522", radius_km: "20")
  end

  test "filters by city" do
    paris = space_at("Paris", city: "Paris")
    space_at("Montreuil", city: "Montreuil")

    assert_equal [paris], search(city: "Paris")
  end

  def slot(space, weekday, from, to, active: true)
    space.recurring_availabilities.create!(weekday:, start_time: from, end_time: to, active:)
  end

  test "filters by weekday and moment, keeping spaces without slots last" do
    monday_morning = create_space(name: "Lundi matin", days: -3)
    slot(monday_morning, 0, "09:00", "12:00")
    monday_evening = create_space(name: "Lundi soir", days: -2)
    slot(monday_evening, 0, "17:00", "20:00")
    tuesday = create_space(name: "Mardi", days: -1)
    slot(tuesday, 1, "09:00", "17:00")
    unknown = create_space(name: "Texte libre", days: -4)
    inactive = create_space(name: "Inactif", days: -5)
    slot(inactive, 0, "09:00", "12:00", active: false)

    assert_equal [monday_evening, monday_morning, unknown, inactive], search(weekday: "0")
    assert_equal [monday_evening, unknown, inactive], search(weekday: "0", moment: "evening")
    assert_equal [tuesday, monday_morning, unknown, inactive], search(moment: "morning")
  end

  test "a slot matches a moment it overlaps" do
    space = create_space(name: "Après-midi")
    slot(space, 2, "10:00", "16:00")

    assert_equal [space], search(moment: "morning")
    assert_equal [space], search(moment: "afternoon")
    assert_empty search(moment: "evening")
  end

  test "marks spaces without slots only when filtering by slot" do
    space = create_space(name: "Texte libre")

    assert_not SpaceSearch.new({}).slots_unknown?(space)
    assert SpaceSearch.new(moment: "evening").slots_unknown?(space)
  end

  test "ignores unknown weekdays and moments" do
    space = create_space(name: "Ici")
    search = SpaceSearch.new(weekday: "9", moment: "night")

    assert_not search.slot_filter?
    assert_equal [space], search.results.to_a
  end

  test "keeps the distance order within slot matches" do
    near = space_at("Proche", latitude: 48.8566, longitude: 2.3522)
    far = space_at("Loin", latitude: 48.90, longitude: 2.40)
    [near, far].each { |space| slot(space, 0, "09:00", "12:00") }

    results = search(near_lat: "48.8566", near_lon: "2.3522", radius_km: "20", weekday: "0")
    assert_equal [near, far], results
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
