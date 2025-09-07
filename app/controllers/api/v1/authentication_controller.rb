module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authorize_request, only: [:login]
      
      def login
        user = User.authenticate_user(login_params[:email], login_params[:password])
        
        if user
          token = JwtService.generate_token(user)
          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email,
              role: user.role,
              external_id: user.external_id,
              first_name: user.first_name,
              last_name: user.last_name
            }
          }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end
      
      def validate
        if current_user
          render json: {
            valid: true,
            user: {
              id: current_user.id,
              email: current_user.email,
              role: current_user.role,
              external_id: current_user.external_id
            }
          }, status: :ok
        else
          render json: { valid: false }, status: :unauthorized
        end
      end
      
      private
      
      def login_params
        params.permit(:email, :password)
      end
    end
  end
end