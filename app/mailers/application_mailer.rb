class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Espace-ouvert <no-reply@arbitryum.fr>")
  layout "mailer"
end
