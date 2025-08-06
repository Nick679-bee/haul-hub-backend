# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin user
admin = User.find_or_create_by(email: 'admin@haulhub.com') do |user|
  user.password = 'password123'
  user.name = 'Admin User'
  user.phone = '555-0001'
  user.role = 'admin'
end

# Create dispatcher user
dispatcher = User.find_or_create_by(email: 'dispatcher@haulhub.com') do |user|
  user.password = 'password123'
  user.name = 'John Dispatcher'
  user.phone = '555-0002'
  user.role = 'dispatcher'
end

# Create driver user
driver = User.find_or_create_by(email: 'driver@haulhub.com') do |user|
  user.password = 'password123'
  user.name = 'Mike Driver'
  user.phone = '555-0003'
  user.role = 'driver'
end

# Create sample trucks for the driver
if driver.trucks.empty?
  driver.trucks.create!(
    make: 'Freightliner',
    model: 'Cascadia',
    year: 2022,
    license_plate: 'ABC123',
    vin: '1FUJA6CV12L123456',
    capacity: 80000.0,
    fuel_type: 'diesel',
    status: 'available',
    insurance_expiry: 1.year.from_now,
    registration_expiry: 1.year.from_now,
    last_maintenance: 2.months.ago,
    notes: 'Primary truck for long hauls'
  )

  driver.trucks.create!(
    make: 'Peterbilt',
    model: '579',
    year: 2021,
    license_plate: 'XYZ789',
    vin: '1XPBD49X7MD123456',
    capacity: 75000.0,
    fuel_type: 'diesel',
    status: 'maintenance',
    insurance_expiry: 6.months.from_now,
    registration_expiry: 8.months.from_now,
    last_maintenance: 7.months.ago,
    notes: 'Backup truck, needs maintenance'
  )

  driver.trucks.create!(
    make: 'Kenworth',
    model: 'T680',
    year: 2023,
    license_plate: 'DEF456',
    vin: '1XKWD49X7MD123456',
    capacity: 85000.0,
    fuel_type: 'diesel',
    status: 'available',
    insurance_expiry: 2.years.from_now,
    registration_expiry: 2.years.from_now,
    last_maintenance: 1.month.ago,
    notes: 'New truck for heavy loads'
  )
end

puts "Seed data created successfully!"
puts "Admin: admin@haulhub.com / password123"
puts "Dispatcher: dispatcher@haulhub.com / password123"
puts "Driver: driver@haulhub.com / password123"
