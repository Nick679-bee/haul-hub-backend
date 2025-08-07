module JwtAuthenticatable
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_user_from_token!
  end
  
  private
  
  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { status: 'error', message: 'No token provided' }, status: :unauthorized unless token
    
    begin
      secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY'] || 'development_jwt_secret_key_please_change_in_production_environment_2024'
      decoded = JWT.decode(token, secret, true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Invalid token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def user_signed_in?
    !!current_user
  end
end



