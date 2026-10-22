require "test_helper"

class EhpadRegistrationTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  VALID = {
    establishment_name: "EHPAD Les Glycines", legal_status: "public", group_name: "Groupe Soleil",
    street: "1 rue des Tilleuls", postal_code: "75011", city: "Paris", contact_name: "Marie Dupont",
    email_address: "contact@example.org", password: "A-strong-password-123", password_confirmation: "A-strong-password-123",
    modules: ["coworking"], coworking_space: "yes"
  }.freeze

  def photo = fixture_file_upload("photo.jpg", "image/jpeg")

  def space(**attributes)
    {name: "Salle polyvalente", description: "40 m², tables et chaises",
     slots: {"2" => {"enabled" => "1", "start_time" => "14:00", "end_time" => "18:00"}, "4" => {"enabled" => "0"}}, **attributes}
  end

  def save(**attributes)
    registration = EhpadRegistration.new(VALID.merge(attributes))
    saved = Geocoder.stub(:geocode, nil) { registration.save }
    [saved, registration]
  end

  test "creates the account, its pending profile and its care home" do
    saved, = save(coworking_photos: [photo])
    assert saved

    user = User.find_by!(email_address: "contact@example.org")
    assert user.ehpad_profile.pending?
    assert_not user.can_sign_in?
    care_home = user.ehpad_profile.care_homes.sole
    assert_equal ["EHPAD Les Glycines", "1 rue des Tilleuls, 75011 Paris", "public", "Groupe Soleil", "Marie Dupont", "contact@example.org", true],
      care_home.values_at(:name, :address, :legal_status, :group_name, :contact_name, :contact_email, :offers_coworking)
    assert_equal 1, care_home.coworking_photos.count
    assert user.ehpad_profile.participates_in_coworking
  end

  test "creates the association spaces as drafts, with their slots and photos" do
    saved, = save(modules: ["spaces"], spaces: {"0" => space(photos: [photo]), "1" => space(name: "Jardin", slots: {})})
    assert saved

    care_home = CareHome.find_by!(name: "EHPAD Les Glycines")
    assert_not care_home.offers_coworking
    room, garden = care_home.spaces.order(:name).to_a.rotate
    assert_equal ["Salle polyvalente", true, 1], [room.name, room.draft?, room.images.count]
    assert_equal [[2, "14:00", "18:00"]], room.recurring_availabilities.map { |slot| [slot.weekday, slot.start_time.strftime("%H:%M"), slot.end_time.strftime("%H:%M")] }
    assert_empty garden.recurring_availabilities
    assert_empty Space.listed
  end

  test "coworking needs a closed space" do
    saved, registration = save(coworking_space: "no")

    assert_not saved
    assert_match "il faut avoir un espace", registration.errors[:coworking_space].first
    assert_not User.exists?(email_address: "contact@example.org")
  end

  test "the association needs described spaces with consistent hours" do
    saved, registration = save(modules: ["spaces"])
    assert_not saved
    assert_includes registration.errors[:spaces], "Ajoutez au moins un espace."

    bad_hours = {"2" => {"enabled" => "1", "start_time" => "18:00", "end_time" => "14:00"}}
    saved, registration = save(modules: ["spaces"], spaces: {"0" => space(description: "", slots: bad_hours)})
    assert_not saved
    assert_includes registration.errors[:spaces], "L'espace 1 est à compléter."
    assert_equal ["Description de l'espace doit être rempli(e)",
      "Disponibilités de l'espace le mercredi : indiquez une heure de début et une heure de fin, dans cet ordre"],
      registration.spaces.first.errors.full_messages
  end

  test "checks the photos" do
    text = fixture_file_upload("photo.jpg", "text/plain")
    _, registration = save(coworking_photos: [photo] * 7 + [text])

    assert_equal %i[too_many_photos photo_type], registration.errors.details[:coworking_photos].pluck(:error)
  end

  test "requires a module, a valid postal code and status" do
    _, registration = save(modules: [""], postal_code: "7501", legal_status: "autre")

    assert_includes registration.errors[:modules], "Sélectionnez au moins un dispositif."
    assert registration.errors[:postal_code].any?
    assert registration.errors[:legal_status].any?
  end

  test "reports password and email errors from the user" do
    _, registration = save(email_address: "Approved@example.com", password: "12345678", password_confirmation: "12345678")

    assert registration.errors[:password].any?
    assert registration.errors[:email_address].any?
    assert_not EhpadProfile.exists?(establishment_name: "EHPAD Les Glycines")
  end

  test "a geocoding failure doesn't stop the registration" do
    registration = EhpadRegistration.new(VALID)

    assert Geocoder.stub(:geocode, ->(_) { raise Geocoder::Error, "down" }) { registration.save }
    assert CareHome.exists?(name: "EHPAD Les Glycines")
  end

  test "approving the profile publishes its spaces" do
    save(modules: ["spaces"], spaces: {"0" => space})
    profile = EhpadProfile.find_by!(establishment_name: "EHPAD Les Glycines")

    profile.update!(status: "approved")

    assert_equal ["Salle polyvalente"], Space.listed.map(&:name)
  end
end
