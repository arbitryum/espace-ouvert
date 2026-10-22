# Back office, restricted to admin users.
namespace :madmin, path: "admin" do
  resources :ehpad_profiles
  resources :care_homes
  resources :hosting_requests, only: %i[index show]
  resources :addresses
  resources :spaces
  resources :space_images
  resources :recurring_availabilities
  resources :coworking_projects
  resources :guide_pages
  resources :guide_readers
  resources :nonprofit_organizations
  resources :users
  resources :admin_invitations, path: "invitations", only: %i[new create]
  root to: "dashboard#show"
end
