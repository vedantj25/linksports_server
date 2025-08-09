Rails.application.routes.draw do
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "login", to: redirect("/users/sign_in")

    resources :users, only: [ :index, :show, :edit, :update ] do
      collection do
        get :search
      end
      member do
        patch :activate
        patch :deactivate
        patch :ban
        patch :unban
        patch :soft_delete
        patch :restore
        patch :verify_email
        patch :verify_phone
        patch :reset_password
        patch :force_logout
      end
    end

    resources :profiles, only: [ :index, :show, :edit, :update ]

    resources :posts, only: [ :index, :show, :update, :destroy ] do
      member do
        patch :hide
        patch :unhide
        patch :soft_delete
        patch :restore
        patch :disable_comments
        patch :enable_comments
      end
    end

    resources :comments, only: [ :index, :show, :destroy ] do
      member do
        patch :soft_delete
        patch :restore
      end
    end

    resources :likes, only: [ :index, :destroy ]
    resources :sports
    resources :connections, only: [ :index, :destroy ]
    resources :user_contacts, only: [ :index, :update ]

    resources :invitations, only: [ :index, :new, :create ] do
      collection do
        get :accept
      end
    end
  end
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/verify_email", to: "auth#verify_email"
      post "auth/resend_email_code", to: "auth#resend_email_code"
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

  # Posts
  resources :posts, only: [ :create ]

  # Sharing routes (username-based)
  get "/profile/:username", to: "shares#show", as: :public_profile
  # Authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Phone verification routes
  # Email verification routes
  get "/verify_email", to: "email_verification#show"
  post "/verify_email", to: "email_verification#verify"
  post "/resend_email_code", to: "email_verification#resend"

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
