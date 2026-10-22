class HostingRequestsMailer < ApplicationMailer
  helper HostingRequestsHelper

  # To the care home (see CareHome#request_recipients): replying writes to the
  # visitor. Admins get a blind copy to follow the requests.
  def received(request)
    @request = request
    # An account answers from its requests page.
    @account_url = account_hosting_requests_url if request.care_home.ehpad_profile&.approved?
    recipients = request.care_home.request_recipients
    mail to: recipients, bcc: User.where(admin: true).pluck(:email_address) - recipients, reply_to: request.email,
      subject: default_i18n_subject(organization: request.organization_name)
  end

  # To the visitor, when the care home refuses. The reason isn't shared.
  def refusal(request)
    @request = request
    # The directory matching what they were looking for.
    @directory_url = request.coworking? ? coworking_projects_url : spaces_url
    mail to: request.email, subject: default_i18n_subject(care_home: request.care_home.name)
  end

  # To an establishment whose requests wait for an answer (see HostingRequestReminders).
  def reminder(profile, count)
    @count = count
    @url = account_hosting_requests_url
    mail to: profile.user.email_address
  end

  # To the visitor, confirming the request went through.
  def acknowledgment(request)
    @request = request
    mail to: request.email, subject: default_i18n_subject(care_home: request.care_home.name)
  end
end
