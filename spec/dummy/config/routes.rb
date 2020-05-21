Rails.application.routes.draw do
  resource :session, controller: 'rails_jwt_auth/sessions', only: %i[create destroy]
  resource :registration, controller: 'rails_jwt_auth/registrations', only: %i[create]
  resource :profile, controller: 'rails_jwt_auth/profiles', only: %i[show update] do
    collection do
      put :email
      put :password
    end
  end

  resources :confirmations, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]
  resources :passwords, controller: 'rails_jwt_auth/passwords', only: [:show, :create, :update]
  resources :invitations, controller: 'rails_jwt_auth/invitations', only: [:show, :create, :update]
  resources :unlocks, controller: 'rails_jwt_auth/unlocks', only: %i[update]
end
