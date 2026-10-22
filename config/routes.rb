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
    resources :passwords, path: "mot-de-passe", param: :token, only: %i[new create edit update],
      path_names: {new: "oublie", edit: "nouveau"}
    resources :invitations, path: "invitation", param: :token, only: %i[edit update], path_names: {edit: "accepter"}
  end

  # The establishment's own space: the requests sent to its care homes.
  namespace :account, path: "comptes/etablissement" do
    resources :hosting_requests, path: "demandes", only: :index do
      member do
        patch :accept, path: "accepter"
        get :refusal, path: "refuser"
        patch :refuse, path: "refuser"
      end
    end
  end

  resources :spaces, only: %i[index show] do
    get "location-suggestions", on: :collection, to: "location_suggestions#index", as: :location_suggestions
  end

  resources :care_homes, path: "etablissements", only: :show do
    resources :hosting_requests, path: "demandes", only: %i[new create], path_names: {new: "nouvelle"}
  end

  get "coworking", to: "coworking#show", as: :coworking
  namespace :coworking do
    get "annuaire", to: "care_homes#index", as: :directory
    # The directory used to list coworking projects.
    get "projets", to: redirect("/coworking/annuaire")
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
