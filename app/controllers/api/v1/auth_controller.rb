class Api::V1::AuthController < ApplicationController

  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY'] || 'development_jwt_secret_key_please_change_in_production_environment_2024'
      
      token = JWT.encode(
        { 
          user_id: user.id,
          email: user.email,
          role: user.role,
          exp: 24.hours.from_now.to_i 
        }, 
        secret
      )

      render json: {
        status: 'success',
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          token: token
        }
      }
    else
      render json: {
        status: 'error',
        message: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  def logout
    # In a real application, you might want to blacklist the token
    # For now, we'll just return a success response
    render json: {
      status: 'success',
      message: 'Logout successful'
    }
  end

  def me
    secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY'] || 'development_jwt_secret_key_please_change_in_production_environment_2024'
    
    begin
      token = request.headers['Authorization']&.split(' ')&.last
      
      if token
        decoded_token = JWT.decode(token, secret, true, { algorithm: 'HS256' })
        user_id = decoded_token[0]['user_id']
        user = User.find(user_id)
        
        render json: {
          status: 'success',
          data: {
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role
            }
          }
        }
      else
        render json: {
          status: 'error',
          message: 'No token provided'
        }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: {
        status: 'error',
        message: 'Invalid token'
      }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        message: 'User not found'
      }, status: :not_found
    end
  end
end
