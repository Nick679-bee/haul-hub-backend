class Api::V1::AuthController < ApplicationController
  # POST /api/v1/auth/login
  def login
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      # Create JWT token manually
      payload = { 
        user_id: user.id,
        email: user.email,
        exp: 24.hours.from_now.to_i
      }
      secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY']
      token = JWT.encode(payload, secret, 'HS256')
      
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
  
  # POST /api/v1/auth/logout
  def logout
    # JWT tokens are stateless, so logout is handled client-side
    # The token will be invalidated on the next request if using JWT denylist
    render json: {
      status: 'success',
      message: 'Logout successful'
    }
  end
  
  # GET /api/v1/auth/me
  def me
    # Extract user from JWT token
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { status: 'error', message: 'No token provided' }, status: :unauthorized unless token
    
    begin
      secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY']
      decoded = JWT.decode(token, secret, true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
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
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Invalid token' }, status: :unauthorized
    end
  end
end
