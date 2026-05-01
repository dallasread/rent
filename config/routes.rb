require "ruby_event_store/browser/app"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "/login",        to: "logins#new",     as: :login
  post "/login",        to: "logins#create"
  get  "/login/verify", to: "logins#verify",  as: :login_verify
  post "/login/verify", to: "logins#submit"
  delete "/logout",     to: "sessions#destroy", as: :logout

  resources :properties, except: [ :show ] do
    member do
      post :duplicate
      post :publish
      post :unpublish
      post :attach_photo
      post :detach_photo
      post :reorder_photos
    end
  end
  get  "/properties/:slug",       to: "properties#show",  as: :property_public
  get  "/properties/:slug/apply", to: "applicants#apply", as: :apply_property
  post "/properties/:slug/apply", to: "applicants#submit"

  resources :applicants, only: [ :index, :show, :new, :create ] do
    member do
      post :archive
      post :unarchive
    end
  end

  resources :leases, only: [ :index, :show, :create, :edit, :update ] do
    member do
      post :archive
      post :unarchive
    end
  end
  get "/applicants/:applicant_id/leases/new", to: "leases#new", as: :new_applicant_lease
  get  "/rentroll",                  to: redirect("/leases")
  post "/rentroll/record/:lease_id", to: "rent_roll#record", as: :record_rent_roll

  resources :tenants, only: [ :index, :show ]

  resources :transactions, only: [ :index, :show, :create, :edit, :update ] do
    member do
      post :mark_paid
      post :archive
      post :unarchive
    end
  end
  get "/leases/:lease_id/transactions/new", to: "transactions#new", as: :new_lease_transaction

  resources :taxes, only: [ :index, :show, :new, :create, :edit, :update ]
  resources :api_tokens, only: [ :index, :new, :create, :destroy ]
  get   "/settings", to: "settings#show",   as: :settings
  patch "/settings", to: "settings#update"
  get   "/audit",    to: "audit#index",     as: :audit
  get "/api/v1", to: "api_docs#show", as: :api_docs

  mount HttpBasicAuth.new(
    RubyEventStore::Browser::App.for(
      event_store_locator: -> { Rails.configuration.event_store }
    ),
    password: ENV["RES_BASIC_PASSWORD"]
  ), at: "/res"

  get "/dashboard", to: "dashboard#show", as: :dashboard
  root "dashboard#show"
end
