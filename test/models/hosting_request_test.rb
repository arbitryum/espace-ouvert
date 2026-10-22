require "test_helper"

class HostingRequestTest < ActiveSupport::TestCase
  def build(**attributes)
    HostingRequest.new(care_home: create_care_home, organization_name: "Les Petits Pas", contact_name: "Léa",
      email: " Lea@Example.org ", message: "Un atelier théâtre le mercredi.", **attributes)
  end

  test "is pending by default, with a normalized email" do
    request = build
    assert request.valid?
    assert request.pending?
    assert_equal "lea@example.org", request.email
  end

  test "requires the visitor's details and need" do
    request = HostingRequest.new(care_home: create_care_home)
    assert_not request.valid?
    assert_equal %i[contact_name email message organization_name], request.errors.attribute_names.sort
  end

  test "rejects a space of another care home" do
    request = build(space: create_space(name: "Ailleurs"))
    assert_not request.valid?
    assert_includes request.errors[:space], "appartient à un autre établissement"
  end
end
