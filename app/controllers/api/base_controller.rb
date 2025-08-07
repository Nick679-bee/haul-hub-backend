class Api::BaseController < ApplicationController
  include JwtAuthenticatable
  
  # Handle authentication errors
  rescue_from JWT::DecodeError, with: :invalid_token
  
  private
  
  def invalid_token
    render json: {
      status: 'error', 
      message: 'Invalid token'
    }, status: :unauthorized
  end
end
