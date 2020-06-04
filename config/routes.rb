Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  devise_scope :user do
    get 'user_addresses', to: 'users/registrations#new_user_address'
    post 'user_addresses', to: 'users/registrations#create_user_address'
  end
  root to: 'items#index'
  resources :users
  resources :items do
    member do
      get 'buy'
    end
  end
  resources :cards
end