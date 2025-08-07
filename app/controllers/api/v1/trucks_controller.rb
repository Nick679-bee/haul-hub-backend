class Api::V1::TrucksController < Api::BaseController
  before_action :set_truck, only: [:show, :update, :destroy]

  # GET /api/v1/trucks
  def index
    @trucks = current_user.trucks
    render json: {
      status: 'success',
      data: @trucks.map(&:full_details)
    }
  end

  # GET /api/v1/trucks/:id
  def show
    render json: {
      status: 'success',
      data: @truck.full_details
    }
  end

  # POST /api/v1/trucks
  def create
    @truck = current_user.trucks.build(truck_params)
    
    if @truck.save
      render json: {
        status: 'success',
        message: 'Truck created successfully',
        data: @truck.full_details
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to create truck',
        errors: @truck.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/trucks/:id
  def update
    if @truck.update(truck_params)
      render json: {
        status: 'success',
        message: 'Truck updated successfully',
        data: @truck.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to update truck',
        errors: @truck.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/trucks/:id
  def destroy
    if @truck.destroy
      render json: {
        status: 'success',
        message: 'Truck deleted successfully'
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to delete truck',
        errors: @truck.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/trucks/available
  def available
    @trucks = current_user.trucks.available
    render json: {
      status: 'success',
      data: @trucks.map(&:full_details)
    }
  end

  # GET /api/v1/trucks/expiring_soon
  def expiring_soon
    @trucks = current_user.trucks.expiring_soon
    render json: {
      status: 'success',
      data: @trucks.map(&:full_details)
    }
  end

  # GET /api/v1/trucks/needs_maintenance
  def needs_maintenance
    @trucks = current_user.trucks.needs_maintenance
    render json: {
      status: 'success',
      data: @trucks.map(&:full_details)
    }
  end

  private

  def set_truck
    @truck = current_user.trucks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Truck not found'
    }, status: :not_found
  end

  def truck_params
    params.require(:truck).permit(
      :make, :model, :year, :license_plate, :vin, :capacity,
      :fuel_type, :status, :insurance_expiry, :registration_expiry,
      :last_maintenance, :notes
    )
  end
end
