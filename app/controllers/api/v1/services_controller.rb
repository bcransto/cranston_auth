module Api
  module V1
    class ServicesController < ApplicationController
      skip_before_action :authorize_request
      before_action :authenticate_service_request!
      
      # GET /api/v1/services/users/:external_id
      def user_by_external_id
        user = User.active.find_by(external_id: params[:external_id])
        
        if user
          render json: user_profile_data(user)
        else
          render json: { error: 'User not found' }, status: :not_found
        end
      end
      
      # GET /api/v1/services/users
      # Params: external_ids[] array
      def users_by_external_ids
        external_ids = params[:external_ids] || []
        
        if external_ids.empty?
          return render json: { error: 'external_ids parameter required' }, status: :bad_request
        end
        
        users = User.active.where(external_id: external_ids)
        render json: users.map { |user| user_profile_data(user) }
      end
      
      private
      
      def user_profile_data(user)
        {
          external_id: user.external_id,
          email: user.email,
          role: user.role,
          lasid: user.lasid,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: user.nickname,
          date_of_birth: user.date_of_birth,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end