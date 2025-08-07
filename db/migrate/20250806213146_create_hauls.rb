class CreateHauls < ActiveRecord::Migration[7.0]
  def change
    create_table :hauls do |t|
      # Relationships
      t.references :user, null: false, foreign_key: true # Customer who created the haul
      t.references :truck, null: true, foreign_key: true # Assigned truck
      #t.references :driver, null: true, foreign_key: { to_table: :users } # Assigned driver
      
      # Haul Details
      t.string :haul_number, null: false # Unique identifier
      t.string :status, default: 'pending'
      t.string :haul_type # 'pickup_delivery', 'one_way', 'round_trip'
      
      # Pickup Information
      t.string :pickup_address, null: false
      t.string :pickup_city
      t.string :pickup_state
      t.string :pickup_zip
      t.decimal :pickup_latitude, precision: 10, scale: 6
      t.decimal :pickup_longitude, precision: 10, scale: 6
      t.datetime :pickup_date
      t.string :pickup_contact_name
      t.string :pickup_contact_phone
      t.text :pickup_instructions
      
      # Delivery Information
      t.string :delivery_address, null: false
      t.string :delivery_city
      t.string :delivery_state
      t.string :delivery_zip
      t.decimal :delivery_latitude, precision: 10, scale: 6
      t.decimal :delivery_longitude, precision: 10, scale: 6
      t.datetime :delivery_date
      t.string :delivery_contact_name
      t.string :delivery_contact_phone
      t.text :delivery_instructions
      
      # Load Information
      t.string :load_type # 'construction_materials', 'furniture', 'equipment', etc.
      t.text :load_description
      t.decimal :load_weight, precision: 10, scale: 2
      t.decimal :load_volume, precision: 10, scale: 2
      t.boolean :load_hazardous, default: false
      t.text :special_requirements
      
      # Distance and Route
      t.decimal :distance_miles, precision: 8, scale: 2
      t.decimal :estimated_duration_hours, precision: 6, scale: 2
      
      # Pricing
      t.decimal :quoted_price, precision: 10, scale: 2
      t.decimal :final_price, precision: 10, scale: 2
      t.decimal :fuel_cost, precision: 8, scale: 2
      t.string :payment_status, default: 'pending'
      t.string :payment_method
      
      # Tracking
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes
      t.text :completion_notes

      t.timestamps
    end
    
    add_index :hauls, :haul_number, unique: true
    add_index :hauls, :status
    add_index :hauls, :pickup_date
    add_index :hauls, :delivery_date
    add_index :hauls, [:user_id, :status]
  end
end
