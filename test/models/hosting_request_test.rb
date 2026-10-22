require "test_helper"

class HostingRequestTest < ActiveSupport::TestCase
  setup { @care_home = create_care_home }

  def build(**attributes)
    @care_home.hosting_requests.new(first_name: "Léa", last_name: "Martin", email: " Lea@Example.org ",
      organization_name: "Les Petits Pas", activity: "Théâtre pour enfants", activity_type: "Un atelier théâtre.",
      attendees: 12, **attributes)
  end

  def coworking(**attributes)
    build(kind: "coworking", team_size: 3, days_per_week: 2, weekdays: ["", "0", "3"], compensation: "both",
      needs: ["", "wifi", "other"], needs_other: "Imprimante", **attributes)
  end

  test "is pending by default, with a normalized email and the full name as contact" do
    request = build
    assert request.valid?
    assert request.pending?
    assert_equal "lea@example.org", request.email
    assert_equal "Léa Martin", request.contact_name
    assert_equal "Léa", request.greeting_name
  end

  test "requires the visitor's details and the association's answers" do
    request = @care_home.hosting_requests.new
    assert_not request.valid?
    assert_equal %i[activity activity_type attendees contact_name email first_name last_name organization_name],
      request.errors.attribute_names.sort
  end

  test "requires the coworking answers, with days or flexibility" do
    request = @care_home.hosting_requests.new(kind: "coworking")
    assert_not request.valid?
    assert_includes request.errors.attribute_names, :team_size
    assert_includes request.errors.attribute_names, :days_per_week
    assert_includes request.errors.attribute_names, :compensation
    assert_includes request.errors.attribute_names, :weekdays

    request = coworking(weekdays: [], flexible_days: true)
    assert request.valid?
  end

  test "keeps the answers of its kind only" do
    request = coworking(space: create_space(name: "Salle", care_home: @care_home), slots: ["x"], contribution: "Un concert")
    request.save!

    assert_equal [[0, 3], %w[wifi other], nil, [], "", nil], [request.weekdays, request.needs, request.space, request.slots, request.contribution, request.attendees]

    request = build(website: "https://example.org", team_size: 3, needs: ["wifi"])
    request.save!
    assert_equal ["", nil, []], [request.website, request.team_size, request.needs]
  end

  test "accepts only the care home's slots, and known days and needs" do
    space = create_space(name: "Salle", care_home: @care_home)
    space.recurring_availabilities.create!(weekday: 2, start_time: "14:00", end_time: "18:00")

    assert build(slots: ["Salle – Mercredi 14:00 – 18:00"]).valid?
    assert_includes build(slots: ["Ailleurs – Lundi 09:00 – 12:00"]).tap(&:valid?).errors.attribute_names, :slots
    assert_includes coworking(weekdays: ["6"]).tap(&:valid?).errors.attribute_names, :weekdays
    assert_includes coworking(needs: ["piscine"]).tap(&:valid?).errors.attribute_names, :needs
  end

  test "an older request without the new answers can still be answered" do
    request = create_hosting_request(@care_home)
    request.update_columns(first_name: "", last_name: "", activity: "", activity_type: "", attendees: nil, contact_name: "Léa", message: "Un besoin")

    request.reload.accept!

    assert request.accepted?
  end

  test "rejects a space of another care home" do
    request = build(space: create_space(name: "Ailleurs"))
    assert_not request.valid?
    assert_includes request.errors[:space], "appartient à un autre établissement"
  end
end
