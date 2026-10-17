require "test_helper"

class SpaceTest < ActiveSupport::TestCase
  test "publication status controls public visibility" do
    assert_not Space.new(publication_status: "draft", published_at: Time.current).public?
    assert Space.new(publication_status: "published", published_at: Time.current).public?
    assert_not Space.new(publication_status: "published", status: "full", published_at: Time.current).public?
  end

  test "recurring availabilities are ordered by weekday and start time" do
    space = create_space(name: "Weekly space")
    late = space.recurring_availabilities.create!(weekday: 2, start_time: "14:00", end_time: "16:00")
    early = space.recurring_availabilities.create!(weekday: 1, start_time: "09:00", end_time: "11:00")

    assert_equal [ early, late ], space.recurring_availabilities.reload.to_a
  end

  test "published recently is false for a future space" do
    assert_not Space.new(published_at: 30.days.from_now).published_recently?
  end

  test "published recently is false for an old space" do
    assert_not Space.new(published_at: 1.day.ago - 1.second).published_recently?
  end

  test "published recently is true for a recent space" do
    assert Space.new(published_at: 23.hours.ago - 59.minutes - 59.seconds).published_recently?
  end
end
