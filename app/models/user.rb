class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  # Associations
  has_many :trucks, dependent: :destroy

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
