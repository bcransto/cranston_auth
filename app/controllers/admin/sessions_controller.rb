module Admin
  class SessionsController < ActionController::Base
    layout 'admin_login'
    
    protect_from_forgery with: :exception
    
    def new
      redirect_to admin_root_path if session[:admin_user_id]
    end
    
    def create
      user = User.authenticate_user(params[:email], params[:password])
      
      if user && user.admin?
        session[:admin_user_id] = user.id
        redirect_to admin_root_path, notice: "Welcome back, #{user.first_name || user.email}!"
      else
        flash.now[:alert] = "Invalid email or password, or insufficient privileges"
        render :new, status: :unprocessable_entity
      end
    end
    
    def destroy
      session[:admin_user_id] = nil
      redirect_to admin_login_path, notice: "You have been logged out"
    end
  end
end