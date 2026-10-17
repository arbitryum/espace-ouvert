Rails.application.routes.draw do
  draw :madmin
  root "home#index"

  scope "comptes" do
    get "inscription", to: "registrations#new", as: :new_registration
    post "inscription", to: "registrations#create", as: :registrations
    get "inscription/en-attente", to: "registrations#pending", as: :pending_registration
    get "connexion", to: "sessions#new", as: :new_session
    post "connexion", to: "sessions#create", as: :session
    delete "deconnexion", to: "sessions#destroy", as: :destroy_session
  end

  resources :spaces, only: %i[index show] do
    get "location-suggestions", on: :collection, to: "location_suggestions#index", as: :location_suggestions
  end

  get "coworking", to: "coworking#show", as: :coworking
  namespace :coworking do
    get "projets", to: "projects#index", as: :projects
  end

  # Coworking guide, readable after requesting access by email.
  scope "coworking/guide" do
    get "/", to: "guides#index", as: :guide
    post "acces", to: "guide_accesses#create", as: :guide_access
    get "acces/:token", to: "guide_accesses#show", as: :guide_access_link
    get "images/:id", to: "guide_images#show", as: :guide_image
    get ":slug", to: "guides#show", as: :guide_page
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check
end
