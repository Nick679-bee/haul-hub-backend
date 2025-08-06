class Truck < ApplicationRecord
  belongs_to :user

  # Enums
  enum :status, {
    available: 'available',
    in_use: 'in_use',
    maintenance: 'maintenance',
    out_of_service: 'out_of_service'
  }

  enum :fuel_type, {
    diesel: 'diesel',
    gasoline: 'gasoline',
    electric: 'electric',
    hybrid: 'hybrid'
  }

  # Validations
  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true, numericality: { greater_than: 1900, less_than_or_equal_to: Date.current.year + 1 }
  validates :license_plate, presence: true, uniqueness: true
  validates :vin, presence: true, uniqueness: true, length: { is: 17 }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :fuel_type, presence: true
  validates :status, presence: true
  validates :insurance_expiry, presence: true
  validates :registration_expiry, presence: true

  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :in_use, -> { where(status: 'in_use') }
  scope :maintenance, -> { where(status: 'maintenance') }
  scope :expiring_soon, -> { where('insurance_expiry <= ? OR registration_expiry <= ?', 30.days.from_now, 30.days.from_now) }
  scope :needs_maintenance, -> { where('last_maintenance <= ? OR last_maintenance IS NULL', 6.months.ago) }

  # Callbacks
  before_validation :normalize_vin, if: :vin_changed?
  before_validation :normalize_license_plate, if: :license_plate_changed?

  # Instance methods
  def display_name
    "#{year} #{make} #{model} (#{license_plate})"
  end

  def full_details
    {
      id: id,
      make: make,
      model: model,
      year: year,
      license_plate: license_plate,
      vin: vin,
      capacity: capacity,
      fuel_type: fuel_type,
      status: status,
      insurance_expiry: insurance_expiry,
      registration_expiry: registration_expiry,
      last_maintenance: last_maintenance,
      notes: notes,
      owner: user.name,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def insurance_expired?
    insurance_expiry < Date.current
  end

  def registration_expired?
    registration_expiry < Date.current
  end

  def maintenance_due?
    last_maintenance.nil? || last_maintenance < 6.months.ago
  end

  def available_for_haul?
    available? && !insurance_expired? && !registration_expired?
  end

  def days_until_insurance_expiry
    (insurance_expiry - Date.current).to_i
  end

  def days_until_registration_expiry
    (registration_expiry - Date.current).to_i
  end

  private

  def normalize_vin
    self.vin = vin&.upcase&.strip
  end

  def normalize_license_plate
    self.license_plate = license_plate&.upcase&.strip
  end
end
