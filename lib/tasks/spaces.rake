namespace :spaces do
  desc "Turn the free-text availability of spaces into weekly slots (dry run; APPLY=1 to write, REPLACE=1 to replace existing slots)"
  task parse_availability: :environment do
    AvailabilityImport.run(apply: ENV["APPLY"].present?, replace: ENV["REPLACE"].present?)
  end
end
