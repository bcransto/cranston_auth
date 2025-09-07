module Admin
  class ApplicationController < ActionController::Base
    include Rails.application.routes.url_helpers
    
    layout 'admin'
    before_action :require_admin_login
    
    # Skip API authentication for admin panel
    skip_before_action :authorize_request if respond_to?(:authorize_request)
    
    private
    
    def require_admin_login
      unless current_admin_user
        redirect_to admin_login_path, alert: "Please log in to continue"
      end
    end
    
    def current_admin_user
      @current_admin_user ||= User.find(session[:admin_user_id]) if session[:admin_user_id]
    rescue ActiveRecord::RecordNotFound
      session[:admin_user_id] = nil
      nil
    end
    
    helper_method :current_admin_user
  end
end