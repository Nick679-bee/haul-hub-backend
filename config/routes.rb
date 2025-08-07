# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'
      
      # Trucks Management
      resources :trucks do
        collection do
          get :available
          get :expiring_soon
          get :needs_maintenance
        end
      end
      
      # Hauls Management
      resources :hauls do
        member do
          post :assign        # POST /api/v1/hauls/:id/assign
          post :start         # POST /api/v1/hauls/:id/start  
          post :complete      # POST /api/v1/hauls/:id/complete
          post :cancel        # POST /api/v1/hauls/:id/cancel
        end
        
        collection do
          get :pending_assignment    # GET /api/v1/hauls/pending_assignment
          get :driver_hauls         # GET /api/v1/hauls/driver_hauls
          get :overdue             # GET /api/v1/hauls/overdue
          get :stats               # GET /api/v1/hauls/stats
          post :calculate_price    # POST /api/v1/hauls/calculate_price
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
