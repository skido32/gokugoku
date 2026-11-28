Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1, defaults: { format: :json } do
    resources :accounts, only: :create
    resource :me, only: %i[show update], controller: :me
    resources :transfer_codes, only: :create
    resources :transfers, only: :create
    delete "sessions/others", to: "sessions#destroy_others"
  end
end
