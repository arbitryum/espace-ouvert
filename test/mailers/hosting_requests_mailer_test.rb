require "test_helper"

class HostingRequestsMailerTest < ActionMailer::TestCase
  setup do
    care_home = create_care_home(name: "EHPAD Les Tilleuls", contact_email: "accueil@ehpad.fr")
    @request = create_hosting_request(care_home, space: create_space(name: "Salle polyvalente", care_home:), schedule: "Mercredi 14h-16h")
  end

  test "the care home receives the request and replies to the visitor" do
    mail = HostingRequestsMailer.received(@request)

    assert_equal ["accueil@ehpad.fr"], mail.to
    assert_equal ["admin@example.com"], mail.bcc
    assert_equal ["lea@example.org"], mail.reply_to
    assert_equal "Nouvelle demande : Les Petits Pas", mail.subject
    body = mail.text_part.decoded
    assert_includes body, "Vous avez reçu une nouvelle demande de Les Petits Pas pour occuper vos espaces pour des activités associatives."
    assert_includes body, "Espace : Salle polyvalente"
    assert_includes body, "Adhérents par activité : 12"
    assert_includes body, "Mercredi 14h-16h"
    assert_includes body, "Bonne journée,\n\nL'Équipe Espace-Ouvert by Arbitryum"
  end

  test "admins aren't copied twice when they are the recipients" do
    @request.care_home.update!(contact_email: "")

    mail = HostingRequestsMailer.received(@request)

    assert_equal ["admin@example.com"], mail.to
    assert_empty Array(mail.bcc)
  end

  test "the visitor gets an acknowledgment" do
    mail = HostingRequestsMailer.acknowledgment(@request)

    assert_equal ["lea@example.org"], mail.to
    assert_equal "Votre demande à EHPAD Les Tilleuls", mail.subject
    assert_includes mail.text_part.decoded, "Votre demande a bien été transmise à EHPAD Les Tilleuls."
  end

  test "the visitor is told about a refusal, without the reason" do
    @request.refuse!("Salle en travaux")

    mail = HostingRequestsMailer.refusal(@request)

    assert_equal ["lea@example.org"], mail.to
    body = mail.text_part.decoded
    assert_includes body, "Malheureusement, EHPAD Les Tilleuls ne peut pas accueillir les activités de votre association."
    assert_includes body, "consulter la carte pour trouver d'autres espaces : http://example.com/spaces"
    assert_not_includes body, "travaux"
  end

  test "a coworking refusal points to the coworking directory" do
    @request.update!(kind: "coworking")
    @request.refuse!("")

    body = HostingRequestsMailer.refusal(@request).text_part.decoded

    assert_includes body, "Malheureusement, EHPAD Les Tilleuls ne peut pas vous accueillir en coworking."
    assert_includes body, "/coworking/annuaire"
  end

  test "an account's email links to its requests page" do
    @request.care_home.update!(ehpad_profile: ehpad_profiles(:approved))

    mail = HostingRequestsMailer.received(@request)

    assert_equal ["approved@example.com"], mail.to
    body = mail.text_part.decoded
    assert_includes body, "Vous pouvez consulter le profil de Les Petits Pas et son besoin sur votre compte"
    assert_includes body, "/comptes/etablissement/demandes"
    assert_not_includes body, "Mercredi 14h-16h"
  end

  test "an establishment is reminded of its pending requests" do
    mail = HostingRequestsMailer.reminder(ehpad_profiles(:approved), 3)

    assert_equal ["approved@example.com"], mail.to
    assert_equal "Des demandes vous attendent sur Espace-ouvert", mail.subject
    body = mail.text_part.decoded
    assert_includes body, "Vous avez toujours 3 demandes en attente sur votre compte."
    assert_includes body, "/comptes/etablissement/demandes"
  end

  test "a coworking request lists its answers" do
    request = create_hosting_request(@request.care_home, kind: "coworking", organization_name: "Collectif",
      website: "https://collectif.example", team_size: 3, days_per_week: 2, weekdays: [1, 3], flexible_days: true,
      needs: %w[wifi other], needs_other: "Imprimante", compensation: "moderate_rent")

    body = HostingRequestsMailer.received(request).text_part.decoded

    assert_includes body, "Collaborateurs : 3"
    assert_includes body, "Jours : Mardi, Jeudi, Je suis flexible"
    assert_includes body, "Besoins spécifiques : Wifi, Imprimante"
    assert_includes body, "Rétribution envisagée : Loyer modéré"
    assert_not_includes body, "Adhérents"
  end
end
