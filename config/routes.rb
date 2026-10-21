Rails.application.routes.draw do
  devise_for :users

  resource :budget, only: [ :show ]
  resources :transactions

  root "budgets#show"
end
