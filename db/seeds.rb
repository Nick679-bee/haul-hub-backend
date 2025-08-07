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

# Create some sample hauls for testing
if admin.persisted? && driver.persisted? && dispatcher.persisted?
  
  # Get the first truck for assignments
  first_truck = driver.trucks.first
  
  # Sample haul 1 - Pending
  Haul.find_or_create_by(haul_number: 'H20250807001') do |haul|
    haul.user = admin
    haul.haul_type = 'pickup_delivery'
    haul.pickup_address = '123 Main St'
    haul.pickup_city = 'Nairobi'
    haul.pickup_state = 'Nairobi County'
    haul.pickup_zip = '00100'
    haul.pickup_date = 2.days.from_now
    haul.pickup_contact_name = 'John Smith'
    haul.pickup_contact_phone = '+254712345001'
    haul.pickup_instructions = 'Loading dock at rear'
    
    haul.delivery_address = '456 Oak Ave'
    haul.delivery_city = 'Mombasa'
    haul.delivery_state = 'Mombasa County'
    haul.delivery_zip = '80100'
    haul.delivery_date = 3.days.from_now
    haul.delivery_contact_name = 'Jane Doe'
    haul.delivery_contact_phone = '+254712345002'
    haul.delivery_instructions = 'Call on arrival'
    
    haul.load_type = 'construction_materials'
    haul.load_description = 'Construction sand - 15 tons'
    haul.load_weight = 15000.0
    haul.load_volume = 20.0
    haul.load_hazardous = false
    haul.distance_miles = 300.5
    haul.estimated_duration_hours = 6.5
    haul.status = 'pending'
    haul.quoted_price = haul.calculate_estimated_price
  end
  
  # Sample haul 2 - Assigned
  Haul.find_or_create_by(haul_number: 'H20250807002') do |haul|
    haul.user = dispatcher
    haul.haul_type = 'one_way'
    haul.pickup_address = '789 Industrial Rd'
    haul.pickup_city = 'Kisumu'
    haul.pickup_state = 'Kisumu County'
    haul.pickup_zip = '40100'
    haul.pickup_date = 1.day.from_now
    haul.pickup_contact_name = 'Mike Johnson'
    haul.pickup_contact_phone = '+254712345003'
    
    haul.delivery_address = '321 Commerce St'
    haul.delivery_city = 'Nakuru'
    haul.delivery_state = 'Nakuru County'
    haul.delivery_zip = '20100'
    haul.delivery_date = 1.day.from_now + 4.hours
    haul.delivery_contact_name = 'Sarah Wilson'
    haul.delivery_contact_phone = '+254712345004'
    
    haul.load_type = 'equipment'
    haul.load_description = 'Heavy machinery parts'
    haul.load_weight = 25000.0
    haul.load_volume = 35.0
    haul.load_hazardous = false
    haul.distance_miles = 150.2
    haul.estimated_duration_hours = 3.5
    haul.status = 'assigned'
    haul.truck = first_truck
    haul.assign_driver(driver)
    haul.quoted_price = haul.calculate_estimated_price
  end
  
  puts "Created sample hauls!"
end