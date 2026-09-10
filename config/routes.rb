Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "/healthz", to: "health#show"

  resource :session, only: [:new, :create, :destroy]

  if Rails.env.development?
    get "/dev/login", to: "dev#login"
  end

  root "conversations#index"
  resources :conversations, only: [:index, :show, :create, :edit, :update, :destroy] do
    member do
      post :retitle
      get  :preset
      get  :export, to: "exports#show"
      post :share
      post :archive
    end
  end
  get "/s/:token", to: "shares#show", as: :shared_conversation

  resources :messages, only: [:create] do
    collection { post :stop; post :regenerate }
  end
  mount ActionCable.server => "/cable"
end
