Rails.application.routes.draw do
  devise_for :users

  resource :budget, only: [ :show ] do
    get :insights
  end
  resources :transactions
  resources :accounts, except: [ :show ]
  resources :transfers, only: [ :create, :update, :destroy ]

  root "budgets#show"
end
