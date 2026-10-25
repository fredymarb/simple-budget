class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Require authentication for all actions except those handled by Devise controllers.
  before_action :authenticate_user!, unless: :devise_controller?

  private

  def month_param(value)
    Date.strptime("#{value}-01", "%Y-%m")
  rescue ArgumentError, TypeError
    Date.today.beginning_of_month
  end
end
