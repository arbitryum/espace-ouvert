namespace :guide do
  desc "Replace the coworking guide with a Notion HTML export (DIR=path/to/export)"
  task import: :environment do
    GuideImport.run(ENV.fetch("DIR"))
  end
end
