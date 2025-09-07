Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'authentication#login'
      get 'auth/validate', to: 'authentication#validate'
      
      # Users
      resources :users, except: [:new, :edit] do
        member do
          post 'restore'
        end
      end
      
      # Service-to-service endpoints
      get 'services/users/:external_id', to: 'services#user_by_external_id'
      get 'services/users', to: 'services#users_by_external_ids'
    end
  end

  # Admin routes (with ERB views)
  namespace :admin do
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    
    resources :users do
      collection do
        get 'batch_new'
        post 'batch_create'
      end
      member do
        post 'restore'
      end
    end
    root to: 'users#index'
  end
end
