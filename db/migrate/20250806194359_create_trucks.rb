class CreateTrucks < ActiveRecord::Migration[8.0]
  def change
    create_table :trucks do |t|
      t.string :make
      t.string :model
      t.integer :year
      t.string :license_plate
      t.string :vin
      t.decimal :capacity
      t.string :fuel_type
      t.string :status
      t.date :insurance_expiry
      t.date :registration_expiry
      t.date :last_maintenance
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
