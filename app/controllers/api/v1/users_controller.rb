module Api
  module V1
    class UsersController < ApplicationController
      before_action :admin_only!, only: [:index, :create, :destroy, :restore]
      before_action :set_user, only: [:show, :update, :destroy, :restore]
      before_action :check_authorization, only: [:show, :update]
      
      def index
        users = User.all
        render json: users
      end
      
      def show
        render json: @user
      end
      
      def create
        user = User.new(user_params)
        
        if user.save
          render json: user, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def destroy
        @user.soft_delete
        render json: { message: 'User deleted successfully' }
      end
      
      def restore
        @user.restore
        render json: @user
      end
      
      private
      
      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
      
      def check_authorization
        self_or_admin!(@user.id)
      end
      
      def user_params
        if current_user&.admin?
          params.permit(:email, :password, :role, :lasid, :first_name, :last_name, :nickname, :date_of_birth)
        else
          params.permit(:password, :first_name, :last_name, :nickname, :date_of_birth)
        end
      end
    end
  end
end