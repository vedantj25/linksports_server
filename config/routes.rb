Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/verify_phone", to: "auth#verify_phone"
      post "auth/resend_code", to: "auth#resend_code"
      post "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      # Profiles
      resources :profiles, only: [ :show, :update ] do
        member do
          patch :complete_setup
          post :upload_image
        end
        collection do
          get :me
          get :search
        end
      end

      # Sports
      resources :sports, only: [ :index, :show ] do
        collection do
          get :categories
        end
      end
    end
  end

  # Profile routes
  resources :profiles, except: [ :index, :destroy ] do
    member do
      get :public_view
      patch :complete_setup
    end
  end

  # Sharing routes
  get "/share/profile/:slug", to: "shares#show", as: :share_profile
  # Authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Phone verification routes
  get "/phone_verification", to: "phone_verification#show"
  post "/phone_verification", to: "phone_verification#verify"
  post "/phone_verification/resend", to: "phone_verification#resend"

  # Root route
  root "home#index"

  # Public pages
  get "about", to: "home#about"
  get "contact", to: "home#contact"
  get "privacy", to: "home#privacy"
  get "terms", to: "home#terms"
  get "discover", to: "home#discover"
  get "events", to: "home#events"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
