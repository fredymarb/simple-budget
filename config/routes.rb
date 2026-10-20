Rails.application.routes.draw do
  devise_for :users

  resource :budget, only: [ :show ]

  root "budgets#show"
end
