Rails.application.routes.draw do
  devise_for :users

  resources :budgets, only: [ :show ]

  root "budgets#show"
end
