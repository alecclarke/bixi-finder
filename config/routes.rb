Rails.application.routes.draw do
  root to: "stations#home"

  namespace :api, defaults: { format: :json } do
    resources :stations, only: [ :index ]
  end
end
