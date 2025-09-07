class ApplicationController < ActionController::API
  before_action :authorize_request
  
  private
  
  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    begin
      @decoded = JwtService.decode(header)
      @current_user = User.find(@decoded[:user_id]) if @decoded
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: 'User not found' }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: 'Invalid token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def admin_only!
    render json: { errors: 'Admin access required' }, status: :forbidden unless current_user&.admin?
  end
  
  def self_or_admin!(user_id)
    unless current_user && (current_user.id == user_id || current_user.admin?)
      render json: { errors: 'Unauthorized' }, status: :forbidden
    end
  end
  
  def authenticate_service!
    service_key = request.headers['X-Service-Api-Key']
    
    unless service_key && valid_service_key?(service_key)
      render json: { errors: 'Invalid service credentials' }, status: :unauthorized
    end
  end
  
  private
  
  def valid_service_key?(key)
    # Simple API key validation - in production, use Rails credentials
    # For now, using environment variables for simplicity
    valid_keys = [
      ENV['CLASSROOM_SERVICE_API_KEY'] || 'classroom_service_key_123',
      ENV['GAME_SERVICE_API_KEY'] || 'game_service_key_456',
      ENV['STORE_SERVICE_API_KEY'] || 'store_service_key_789'
    ]
    
    valid_keys.include?(key)
  end
end
