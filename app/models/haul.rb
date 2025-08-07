class Haul < ApplicationRecord
  belongs_to :user # Customer
  belongs_to :truck, optional: true
  # Remove this line - it conflicts with your method below
  # belongs_to :driver, class_name: 'User', optional: true
  
  # Enums
  enum :status, {
    pending: 'pending',
    quoted: 'quoted', 
    accepted: 'accepted',
    assigned: 'assigned',
    in_progress: 'in_progress',
    completed: 'completed',
    cancelled: 'cancelled'
  }
  
  enum :haul_type, {
    pickup_delivery: 'pickup_delivery',
    one_way: 'one_way',
    round_trip: 'round_trip'
  }
  
  # Fix: Change 'pending' to 'unpaid' to avoid conflict
  enum :payment_status, {
    unpaid: 'unpaid',
    paid: 'paid',
    overdue: 'overdue',
    refunded: 'refunded'
  }
  
  # Validations
  validates :haul_number, presence: true, uniqueness: true
  validates :pickup_address, presence: true
  validates :delivery_address, presence: true
  validates :load_description, presence: true
  validates :pickup_date, presence: true
  validates :delivery_date, presence: true
  validates :haul_type, presence: true
  validates :status, presence: true
  validate :delivery_after_pickup
  validate :truck_available_for_dates, if: :truck_id?
  #validate :driver_is_driver_role, if: :driver_id?
  
  # Scopes
  scope :active, -> { where.not(status: ['completed', 'cancelled']) }
  scope :pending_assignment, -> { where(status: 'accepted', truck: nil) }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed_today, -> { where(status: 'completed', completed_at: Date.current.all_day) }
  scope :overdue, -> { where('delivery_date < ? AND status NOT IN (?)', Time.current, ['completed', 'cancelled']) }
  scope :by_driver, ->(driver_id) { where(driver_id: driver_id) }
  scope :by_truck, ->(truck_id) { where(truck_id: truck_id) }
  
  # Callbacks
  before_validation :generate_haul_number, if: :new_record?
  after_update :update_truck_status, if: :saved_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?
  
  # Instance Methods
  def full_details
    {
      id: id,
      haul_number: haul_number,
      status: status,
      haul_type: haul_type,
      
      # Pickup details
      pickup: {
        address: pickup_address,
        city: pickup_city,
        state: pickup_state,
        zip: pickup_zip,
        date: pickup_date,
        contact_name: pickup_contact_name,
        contact_phone: pickup_contact_phone,
        instructions: pickup_instructions,
        coordinates: pickup_coordinates
      },
      
      # Delivery details
      delivery: {
        address: delivery_address,
        city: delivery_city,
        state: delivery_state,
        zip: delivery_zip,
        date: delivery_date,
        contact_name: delivery_contact_name,
        contact_phone: delivery_contact_phone,
        instructions: delivery_instructions,
        coordinates: delivery_coordinates
      },
      
      # Load information
      load: {
        type: load_type,
        description: load_description,
        weight: load_weight,
        volume: load_volume,
        hazardous: load_hazardous,
        special_requirements: special_requirements
      },
      
      # Assignment
      truck: truck&.display_name,
      driver: driver&.name,
      
      # Financials
      pricing: {
        quoted_price: quoted_price,
        final_price: final_price,
        fuel_cost: fuel_cost,
        payment_status: payment_status,
        payment_method: payment_method
      },
      
      # Route
      distance_miles: distance_miles,
      estimated_duration_hours: estimated_duration_hours,
      
      # Timing
      started_at: started_at,
      completed_at: completed_at,
      
      # Customer
      customer: user.name,
      customer_phone: user.phone,
      
      # Notes
      notes: notes,
      completion_notes: completion_notes,
      
      created_at: created_at,
      updated_at: updated_at
    }
  end
  
  def pickup_coordinates
    return nil unless pickup_latitude && pickup_longitude
    [pickup_latitude, pickup_longitude]
  end
  
  def delivery_coordinates
    return nil unless delivery_latitude && delivery_longitude
    [delivery_latitude, delivery_longitude]
  end
  
  def overdue?
    delivery_date < Time.current && !completed? && !cancelled?
  end
  
  def duration_days
    return 0 unless pickup_date && delivery_date
    ((delivery_date - pickup_date) / 1.day).ceil
  end
  
  def assign_truck_and_driver!(truck, driver)
    transaction do
      update!(
        truck: truck,
        status: 'assigned'
      )
      truck.update!(status: 'in_use')
    end
  end
  
  def start_haul!
    return false unless assigned?
    update!(
      status: 'in_progress',
      started_at: Time.current
    )
  end
  
  def complete_haul!(completion_notes = nil)
    return false unless in_progress?
    transaction do
      update!(
        status: 'completed',
        completed_at: Time.current,
        completion_notes: completion_notes
      )
      truck&.update!(status: 'available')
    end
  end
  
  def cancel_haul!(reason = nil)
    transaction do
      update!(
        status: 'cancelled',
        notes: [notes, "Cancelled: #{reason}"].compact.join(' | ')
      )
      truck&.update!(status: 'available') if truck
    end
  end
  
  def calculate_estimated_price
    # Basic pricing calculation - can be enhanced with more complex logic
    base_rate_per_mile = 2.50
    weight_multiplier = load_weight.to_f > 10000 ? 1.2 : 1.0
    hazardous_multiplier = load_hazardous? ? 1.5 : 1.0
    
    base_cost = (distance_miles || 0) * base_rate_per_mile
    final_cost = base_cost * weight_multiplier * hazardous_multiplier
    
    final_cost.round(2)
  end
  
  # Method to get the assigned driver through truck
  def driver
    truck&.user if truck&.user&.role == 'driver'
  end
  
  # Method to assign a driver
  def assign_driver(driver_user)
    if driver_user.role == 'driver' && driver_user.trucks.any?
      available_truck = driver_user.trucks.where(status: 'available').first
      self.truck = available_truck if available_truck
    end
  end
  
  private
  
  def generate_haul_number
    self.haul_number = "H#{Date.current.strftime('%Y%m%d')}#{sprintf('%04d', (Haul.where('created_at >= ?', Date.current.beginning_of_day).count + 1))}"
  end
  
  def delivery_after_pickup
    return unless pickup_date && delivery_date
    errors.add(:delivery_date, 'must be after pickup date') if delivery_date < pickup_date
  end
  
  def truck_available_for_dates
    return unless truck && pickup_date && delivery_date
    
    conflicting_hauls = Haul.active
      .where(truck: truck)
      .where.not(id: id)
      .where(
        '(pickup_date BETWEEN ? AND ?) OR (delivery_date BETWEEN ? AND ?) OR (pickup_date <= ? AND delivery_date >= ?)',
        pickup_date, delivery_date,
        pickup_date, delivery_date,
        pickup_date, delivery_date
      )
    
    if conflicting_hauls.exists?
      errors.add(:truck, 'is not available for the selected dates')
    end
  end
  
  #def driver_is_driver_role
   # return unless driver
    #errors.add(:driver, 'must have driver role') unless driver.role == 'driver'
  #end
  
  def update_truck_status
    case status
    when 'assigned', 'in_progress'
      truck&.update!(status: 'in_use')
    when 'completed', 'cancelled'
      truck&.update!(status: 'available')
    end
  end
  
  def notify_status_change
    # Add notification logic here
    Rails.logger.info "Haul #{haul_number} status changed to #{status}"
    # HaulNotificationJob.perform_later(self) if Rails.env.production?
  end
end

#back up code
#validate :driver_is_driver_role, if: -> { truck&.user.present? }

#private

#def driver_is_driver_role
 # return unless truck&.user
 # errors.add(:truck, 'must be assigned to a user with driver role') unless truck.user.role == 'driver'
#end