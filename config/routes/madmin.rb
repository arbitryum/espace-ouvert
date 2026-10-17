# Back office, restricted to admin users.
namespace :madmin, path: "admin" do
  resources :ehpad_profiles
  resources :care_homes
  resources :addresses
  resources :spaces
  resources :space_images
  resources :recurring_availabilities
  resources :coworking_projects
  resources :guide_pages
  resources :guide_readers
  resources :nonprofit_organizations
  resources :users
  root to: "dashboard#show"
end
