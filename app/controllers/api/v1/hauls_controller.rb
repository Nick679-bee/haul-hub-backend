class Api::V1::HaulsController < Api::BaseController
  before_action :set_haul, only: [:show, :update, :destroy, :assign, :start, :complete, :cancel]

  # GET /api/v1/hauls
  def index
    @hauls = filter_hauls
    render json: {
      status: 'success',
      data: @hauls.map(&:full_details),
      meta: {
        total: @hauls.count,
        filter: params[:filter]
      }
    }
  end

  # GET /api/v1/hauls/:id
  def show
    render json: {
      status: 'success',
      data: @haul.full_details
    }
  end

  # POST /api/v1/hauls
  def create
    # Handle nested parameters
    haul_attributes = process_nested_params(params)
    
    @haul = current_user.hauls.build(haul_attributes)
    
    # Calculate estimated price if distance provided
    if @haul.distance_miles.present?
      @haul.quoted_price = @haul.calculate_estimated_price
    end
    
    if @haul.save
      render json: {
        status: 'success',
        message: 'Haul created successfully',
        data: @haul.full_details
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to create haul',
        errors: @haul.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/hauls/:id
  def update
    if @haul.update(haul_params)
      render json: {
        status: 'success',
        message: 'Haul updated successfully',
        data: @haul.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to update haul',
        errors: @haul.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/hauls/:id
  def destroy
    if @haul.destroy
      render json: {
        status: 'success',
        message: 'Haul deleted successfully'
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to delete haul'
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/hauls/:id/assign
  def assign
    truck = current_user.trucks.find(params[:truck_id]) if params[:truck_id]
    driver = User.drivers.find(params[:driver_id]) if params[:driver_id]
    
    if truck.nil?
      return render json: {
        status: 'error',
        message: 'Truck not found or not owned by you'
      }, status: :not_found
    end
    
    if driver.nil?
      return render json: {
        status: 'error', 
        message: 'Driver not found or invalid role'
      }, status: :not_found
    end
    
    if @haul.assign_truck_and_driver!(truck, driver)
      render json: {
        status: 'success',
        message: 'Haul assigned successfully',
        data: @haul.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to assign haul',
        errors: @haul.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/hauls/:id/start
  def start
    if @haul.start_haul!
      render json: {
        status: 'success',
        message: 'Haul started successfully',
        data: @haul.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Cannot start haul in current status'
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/hauls/:id/complete
  def complete
    completion_notes = params[:completion_notes]
    
    if @haul.complete_haul!(completion_notes)
      render json: {
        status: 'success',
        message: 'Haul completed successfully',
        data: @haul.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Cannot complete haul in current status'
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/hauls/:id/cancel
  def cancel
    reason = params[:reason]
    
    if @haul.cancel_haul!(reason)
      render json: {
        status: 'success',
        message: 'Haul cancelled successfully',
        data: @haul.full_details
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to cancel haul',
        errors: @haul.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/hauls/pending_assignment
  def pending_assignment
    authorize_dispatcher_or_admin
    
    @hauls = Haul.pending_assignment.includes(:user, :truck, :driver)
    render json: {
      status: 'success',
      data: @hauls.map(&:full_details)
    }
  end

  # GET /api/v1/hauls/driver_hauls
  def driver_hauls
    if current_user.driver?
      @hauls = current_user.assigned_hauls.active.includes(:truck, :user)
    else
      return render json: {
        status: 'error',
        message: 'Access denied: Driver role required'
      }, status: :forbidden
    end
    
    render json: {
      status: 'success',
      data: @hauls.map(&:full_details)
    }
  end

  # GET /api/v1/hauls/overdue
  def overdue
    authorize_dispatcher_or_admin
    
    @hauls = Haul.overdue.includes(:user, :truck, :driver)
    render json: {
      status: 'success',
      data: @hauls.map(&:full_details),
      meta: {
        count: @hauls.count
      }
    }
  end

  # GET /api/v1/hauls/stats
  def stats
    authorize_dispatcher_or_admin
    
    stats = {
      total_hauls: Haul.count,
      pending: Haul.pending.count,
      in_progress: Haul.in_progress.count,
      completed_today: Haul.completed_today.count,
      overdue: Haul.overdue.count,
      total_revenue_month: Haul.completed
        .where(completed_at: Date.current.beginning_of_month..Date.current.end_of_month)
        .sum(:final_price),
      available_trucks: current_user.trucks.available.count
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  # POST /api/v1/hauls/calculate_price
  def calculate_price
    haul = Haul.new(calculate_price_params)
    estimated_price = haul.calculate_estimated_price
    
    render json: {
      status: 'success',
      data: {
        distance_miles: haul.distance_miles,
        load_weight: haul.load_weight,
        hazardous: haul.load_hazardous,
        estimated_price: estimated_price
      }
    }
  end

  private

  def set_haul
    @haul = accessible_hauls.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Haul not found'
    }, status: :not_found
  end

  def accessible_hauls
    case current_user.role
    when 'admin', 'dispatcher'
      Haul.all
    when 'driver'
      Haul.where('user_id = ? OR driver_id = ?', current_user.id, current_user.id)
    else
      current_user.hauls
    end
  end

  def filter_hauls
    hauls = accessible_hauls.includes(:user, :truck)
    
    case params[:filter]
    when 'active'
      hauls.active
    when 'completed'
      hauls.completed
    when 'pending'
      hauls.pending
    when 'in_progress'
      hauls.in_progress
    when 'overdue'
      hauls.overdue
    when 'my_hauls'
      current_user.hauls
    when 'my_assignments'
      current_user.assigned_hauls if current_user.driver?
    else
      hauls.order(created_at: :desc).limit(50) # Limit to recent 50 by default
    end || hauls
  end

  def haul_params
    params.require(:haul).permit(
      :haul_type, :pickup_address, :pickup_city, :pickup_state, :pickup_zip,
      :pickup_latitude, :pickup_longitude, :pickup_date, :pickup_contact_name,
      :pickup_contact_phone, :pickup_instructions, :delivery_address,
      :delivery_city, :delivery_state, :delivery_zip, :delivery_latitude,
      :delivery_longitude, :delivery_date, :delivery_contact_name,
      :delivery_contact_phone, :delivery_instructions, :load_type,
      :load_description, :load_weight, :load_volume, :load_hazardous,
      :special_requirements, :distance_miles, :estimated_duration_hours,
      :quoted_price, :final_price, :fuel_cost, :payment_method, :notes
    )
  end

  def calculate_price_params
    params.permit(:distance_miles, :load_weight, :load_hazardous)
  end

  def authorize_dispatcher_or_admin
    unless current_user.dispatcher? || current_user.admin?
      render json: {
        status: 'error',
        message: 'Access denied: Dispatcher or Admin role required'
      }, status: :forbidden
    end
  end
  
  def process_nested_params(params)
    attributes = {}
    
    # Handle pickup nested object
    if params[:pickup]
      pickup = params[:pickup]
      attributes.merge!(
        pickup_address: pickup[:address],
        pickup_city: pickup[:city],
        pickup_state: pickup[:state],
        pickup_zip: pickup[:zip],
        pickup_date: pickup[:date],
        pickup_contact_name: pickup[:contact_name],
        pickup_contact_phone: pickup[:contact_phone],
        pickup_instructions: pickup[:instructions],
        pickup_latitude: pickup[:coordinates]&.first,
        pickup_longitude: pickup[:coordinates]&.last
      )
    end
    
    # Handle delivery nested object
    if params[:delivery]
      delivery = params[:delivery]
      attributes.merge!(
        delivery_address: delivery[:address],
        delivery_city: delivery[:city],
        delivery_state: delivery[:state],
        delivery_zip: delivery[:zip],
        delivery_date: delivery[:date],
        delivery_contact_name: delivery[:contact_name],
        delivery_contact_phone: delivery[:contact_phone],
        delivery_instructions: delivery[:instructions],
        delivery_latitude: delivery[:coordinates]&.first,
        delivery_longitude: delivery[:coordinates]&.last
      )
    end
    
    # Handle load nested object
    if params[:load]
      load = params[:load]
      attributes.merge!(
        load_type: load[:type],
        load_description: load[:description],
        load_weight: load[:weight],
        load_volume: load[:volume],
        load_hazardous: load[:hazardous],
        special_requirements: load[:special_requirements]
      )
    end
    
    # Handle pricing nested object
    if params[:pricing]
      pricing = params[:pricing]
      attributes.merge!(
        quoted_price: pricing[:quoted_price],
        final_price: pricing[:final_price],
        fuel_cost: pricing[:fuel_cost],
        payment_status: pricing[:payment_status],
        payment_method: pricing[:payment_method]
      )
    end
    
    # Handle direct attributes
    direct_attrs = [:haul_type, :distance_miles, :estimated_duration_hours, :notes, :status]
    direct_attrs.each do |attr|
      attributes[attr] = params[attr] if params[attr]
    end
    
    attributes
  end
end