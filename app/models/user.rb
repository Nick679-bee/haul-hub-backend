class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
       :validatable,
       :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
  # Associations
  has_many :trucks, dependent: :destroy

  # Hauls
has_many :hauls, dependent: :destroy # Hauls created by user as customer
has_many :assigned_hauls, class_name: 'Haul', foreign_key: 'driver_id', dependent: :nullify # Hauls assigned as driver

def active_hauls_as_driver
  assigned_hauls.where.not(status: ['completed', 'cancelled'])
end

def completed_hauls_as_driver
  assigned_hauls.where(status: 'completed')
end


  # Validations
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin driver dispatcher] }

  # Scopes
  scope :drivers, -> { where(role: 'driver') }
  scope :dispatchers, -> { where(role: 'dispatcher') }
  scope :admins, -> { where(role: 'admin') }

  # Instance methods
  def driver?
    role == 'driver'
  end

  def dispatcher?
    role == 'dispatcher'
  end

  def admin?
    role == 'admin'
  end

  def available_trucks
    trucks.available
  end
end
