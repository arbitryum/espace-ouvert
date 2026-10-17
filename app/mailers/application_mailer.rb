class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Espaces Ouverts <no-reply@arbitryum.fr>")
  layout "mailer"
end
