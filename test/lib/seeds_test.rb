require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "coworking seed has published and draft examples" do
    assert_equal 3, Seeds::Coworking::PROJECTS.size
    assert_equal 2, Seeds::Coworking::PROJECTS.count { |project| project[:published] }
  end

  test "coworking seed does not delete spaces and can run twice" do
    create_space(name: "Salle existante")

    2.times { Seeds::Coworking.run(output: StringIO.new) }

    assert_equal 1, Space.count
    assert_equal 3, CoworkingProject.count
  end

  test "availability seed adds slots to the named spaces once" do
    space = create_space(name: "Le forum")

    2.times { Seeds::Availability.run(output: StringIO.new) }

    assert_equal [1, 3], space.recurring_availabilities.pluck(:weekday)
  end

  test "spaces seed data references existing care homes" do
    data = YAML.load_file(Seeds::Spaces::DATA_FILE)
    care_homes = data["care_homes"].pluck("name")

    assert_empty data["spaces"].pluck("care_home") - care_homes
  end
end
