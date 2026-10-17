class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Espaces Ouverts <ne-pas-repondre@example.com>")
  layout "mailer"
end
