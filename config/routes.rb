Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "/login",        to: "logins#new",     as: :login
  post "/login",        to: "logins#create"
  get  "/login/verify", to: "logins#verify",  as: :login_verify
  post "/login/verify", to: "logins#submit"
  delete "/logout",     to: "sessions#destroy", as: :logout

  get "/dashboard", to: "dashboard#show", as: :dashboard
  root "dashboard#show"
end
