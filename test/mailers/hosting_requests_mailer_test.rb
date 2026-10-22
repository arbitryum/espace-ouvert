require "test_helper"

class HostingRequestsMailerTest < ActionMailer::TestCase
  setup do
    care_home = create_care_home(name: "EHPAD Les Tilleuls", contact_email: "accueil@ehpad.fr")
    @request = care_home.hosting_requests.create!(space: create_space(name: "Salle polyvalente", care_home:),
      organization_name: "Les Petits Pas", contact_name: "Léa", email: "lea@example.org",
      message: "Un atelier théâtre le mercredi.", schedule: "Mercredi 14h-16h")
  end

  test "the care home receives the request and replies to the visitor" do
    mail = HostingRequestsMailer.received(@request)

    assert_equal ["accueil@ehpad.fr"], mail.to
    assert_equal ["admin@example.com"], mail.bcc
    assert_equal ["lea@example.org"], mail.reply_to
    assert_equal "Demande d'accueil : Les Petits Pas", mail.subject
    body = mail.text_part.decoded
    assert_includes body, "Les Petits Pas souhaite être accueilli dans votre établissement (Activités associatives)."
    assert_includes body, "Espace demandé : Salle polyvalente"
    assert_includes body, "Mercredi 14h-16h"
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
    assert_includes body, "EHPAD Les Tilleuls ne peut malheureusement pas accueillir Les Petits Pas"
    assert_includes body, "/spaces"
    assert_not_includes body, "travaux"
  end

  test "an account's email links to its requests page" do
    @request.care_home.update!(ehpad_profile: ehpad_profiles(:approved))

    mail = HostingRequestsMailer.received(@request)

    assert_equal ["approved@example.com"], mail.to
    assert_includes mail.text_part.decoded, "/comptes/etablissement/demandes"
  end
end
