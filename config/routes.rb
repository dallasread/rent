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
    end
  end
  get  "/p/:slug",       to: "properties#show",  as: :property_public
  get  "/p/:slug/apply", to: "applicants#apply", as: :apply_property
  post "/p/:slug/apply", to: "applicants#submit"

  resources :applicants, only: [ :index, :show, :new, :create ]

  resources :leases, only: [ :index, :show, :create ]
  get "/applicants/:applicant_id/leases/new", to: "leases#new", as: :new_applicant_lease

  resources :transactions, only: [ :index, :show, :create ] do
    member do
      post :mark_paid
    end
  end
  get "/leases/:lease_id/transactions/new", to: "transactions#new", as: :new_lease_transaction

  resources :api_tokens, only: [ :index, :new, :create, :destroy ]
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
