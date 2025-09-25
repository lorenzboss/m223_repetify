# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  # Translation route
  post "/translate", to: "home#translate"

  # Vocabulary routes
  post "/vocabularies", to: "home#save_vocabulary"
  resources :vocabularies, only: [ :index, :update, :destroy ] do
    collection do
      get :learn # Overview of learning progress by language
      get :learn_language, path: "learn/:language" # Learn specific language
      patch :update_learning_status # Update vocabulary status during learning
    end
  end

  # Admin routes
  resources :admin, only: [ :index ] do
    collection do
      get :activity_log
      patch "users/:id/suspend", to: "admin#suspend", as: "suspend_user"
      patch "users/:id/unsuspend", to: "admin#unsuspend", as: "unsuspend_user"
      patch "users/:id/make_admin", to: "admin#make_admin", as: "make_admin_user"
      patch "users/:id/remove_admin", to: "admin#remove_admin", as: "remove_admin_user"
      patch "users/:id/change_email", to: "admin#change_email", as: "change_email_user"
      patch "users/:id/reset_password", to: "admin#reset_password", as: "reset_password_user"
      delete "users/:id", to: "admin#destroy", as: "delete_user"
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
