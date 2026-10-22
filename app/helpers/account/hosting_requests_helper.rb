module Account::HostingRequestsHelper
  # Opens the establishment's mail app on a pre-written answer to the visitor,
  # with the establishment in copy, to edit before sending.
  def acceptance_mail_to(request, **options, &)
    texts = {name: request.greeting_name, care_home: request.care_home.name, organization: request.organization_name,
             signature: request.care_home.ehpad_profile&.contact_name.to_s}
    mail_to request.email, cc: Current.user.email_address,
      subject: t("account.hosting_requests.acceptance_mail.subject", **texts),
      body: t("account.hosting_requests.acceptance_mail.body.#{request.kind}", **texts), **options, &
  end

  STATUS_BADGES = {"pending" => "badge-warning", "accepted" => "badge-success", "refused" => "badge-ghost"}.freeze

  def hosting_request_status_badge(request)
    tag.span request.human_enum_name(:status), class: "badge #{STATUS_BADGES.fetch(request.status)}"
  end
end
