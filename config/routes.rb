Rails.application.routes.draw do
  root "pages#home"

  get "demo", to: "pages#demo"
  post "demo/generate", to: "demo#generate"

  namespace :api do
    post "plugin/render", to: "plugin#render_block"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
