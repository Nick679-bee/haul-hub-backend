#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'date'

# Configuration
BASE_URL = 'http://localhost:3001'
API_BASE = "#{BASE_URL}/api/v1"

def make_request(method, endpoint, data = nil, token = nil)
  uri = URI("#{API_BASE}#{endpoint}")
  
  case method.upcase
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
  when 'PUT'
    request = Net::HTTP::Put.new(uri)
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  end
  
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{token}" if token
  
  request.body = data.to_json if data
  
  http = Net::HTTP.new(uri.host, uri.port)
  response = http.request(request)
  
  {
    status: response.code,
    body: begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end
  }
rescue => e
  {
    status: 'ERROR',
    body: { error: e.message }
  }
end

def test_authentication
  puts "🔐 Testing API Authentication"
  puts "=" * 50
  
  # Test 1: Login with valid credentials
  puts "\n1. Testing login with valid credentials..."
  login_data = {
    email: 'admin@haulhub.com',
    password: 'password123'
  }
  
  result = make_request('POST', '/auth/login', login_data)
  puts "Status: #{result[:status]}"
  puts "Response: #{JSON.pretty_generate(result[:body])}"
  
  if result[:status] == '200'
    token = result[:body]['data']['token']
    puts "\n✅ Login successful! Token received."
    
    # Test 2: Get current user with token
    puts "\n2. Testing /auth/me with token..."
    me_result = make_request('GET', '/auth/me', nil, token)
    puts "Status: #{me_result[:status]}"
    puts "Response: #{JSON.pretty_generate(me_result[:body])}"
    
    # Test 3: Access protected endpoint (hauls)
    puts "\n3. Testing protected endpoint (hauls) with token..."
    hauls_result = make_request('GET', '/hauls', nil, token)
    puts "Status: #{hauls_result[:status]}"
    puts "Response: #{JSON.pretty_generate(hauls_result[:body])}"
    
    # Test 4: Access protected endpoint without token
    puts "\n4. Testing protected endpoint without token..."
    no_token_result = make_request('GET', '/hauls')
    puts "Status: #{no_token_result[:status]}"
    puts "Response: #{JSON.pretty_generate(no_token_result[:body])}"
    
    # Test 5: Test trucks endpoint
    puts "\n5. Testing trucks endpoint with token..."
    trucks_result = make_request('GET', '/trucks', nil, token)
    puts "Status: #{trucks_result[:status]}"
    puts "Response: #{JSON.pretty_generate(trucks_result[:body])}"
    
  else
    puts "\n❌ Login failed!"
  end
  
  # Test 6: Login with invalid credentials
  puts "\n6. Testing login with invalid credentials..."
  invalid_login = {
    email: 'invalid@example.com',
    password: 'wrongpassword'
  }
  
  invalid_result = make_request('POST', '/auth/login', invalid_login)
  puts "Status: #{invalid_result[:status]}"
  puts "Response: #{JSON.pretty_generate(invalid_result[:body])}"
end

def test_haul_creation
  puts "\n\n🚛 Testing Haul Creation"
  puts "=" * 50
  
  # First login to get token
  login_data = {
    email: 'admin@haulhub.com',
    password: 'password123'
  }
  
  login_result = make_request('POST', '/auth/login', login_data)
  
  if login_result[:status] == '200'
    token = login_result[:body]['data']['token']
    
    # Create a test haul
    haul_data = {
      haul: {
        haul_type: 'pickup_delivery',
        pickup_address: '123 Main St',
        pickup_city: 'Nairobi',
        pickup_state: 'Nairobi',
        pickup_zip: '00100',
        pickup_date: (Date.today + 1).to_s,
        pickup_contact_name: 'John Doe',
        pickup_contact_phone: '+254700000000',
        delivery_address: '456 Oak Ave',
        delivery_city: 'Mombasa',
        delivery_state: 'Mombasa',
        delivery_zip: '80100',
        delivery_date: (Date.today + 2).to_s,
        delivery_contact_name: 'Jane Smith',
        delivery_contact_phone: '+254700000001',
        load_description: 'General cargo',
        load_weight: 5000,
        distance_miles: 300
      }
    }
    
    puts "\nCreating test haul..."
    create_result = make_request('POST', '/hauls', haul_data, token)
    puts "Status: #{create_result[:status]}"
    puts "Response: #{JSON.pretty_generate(create_result[:body])}"
    
    if create_result[:status] == '201'
      haul_id = create_result[:body]['data']['id']
      puts "\n✅ Haul created successfully! ID: #{haul_id}"
      
      # Test getting the created haul
      puts "\nFetching created haul..."
      get_result = make_request('GET', "/hauls/#{haul_id}", nil, token)
      puts "Status: #{get_result[:status]}"
      puts "Response: #{JSON.pretty_generate(get_result[:body])}"
    end
  else
    puts "\n❌ Cannot test haul creation - login failed!"
  end
end

# Run the tests
if __FILE__ == $0
  puts "🚀 Starting API Token Tests"
  puts "=" * 50
  
  test_authentication
  test_haul_creation
  
  puts "\n\n✅ API Token testing completed!"
end
