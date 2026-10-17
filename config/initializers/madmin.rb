# Madmin resources read their table's columns when they load. Leaving them out
# of eager loading lets the app boot before migrations run: Scalingo starts the
# new web container before the postdeploy hook migrates the database.
Rails.autoloaders.main.do_not_eager_load(Rails.root.join("app/madmin/resources"))
