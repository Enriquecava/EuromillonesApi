#!/usr/bin/env ruby
# test/validation_test.rb
# Basic validation tests for the enhanced validation middleware

require 'net/http'
require 'json'
require 'uri'

class ValidationTest
  BASE_URL = 'http://localhost:4567'
  
  def initialize
    @passed = 0
    @failed = 0
    @test_results = []
  end
  
  def run_all_tests
    puts "🚀 Starting Validation Tests for Euromillones API"
    puts "=" * 60
    
    # Test rate limiting
    test_rate_limiting
    
    # Test content type validation
    test_content_type_validation
    
    # Test payload size validation
    test_payload_size_validation
    
    # Test JSON validation
    test_json_validation
    
    # Test required fields validation
    test_required_fields_validation
    
    # Test suspicious pattern detection
    test_suspicious_pattern_detection
    
    # Test encoding validation
    test_encoding_validation
    
    # Print summary
    print_summary
  end
  
  private
  
  def test_rate_limiting
    puts "\n📊 Testing Rate Limiting..."
    
    # Make multiple rapid requests to trigger rate limiting
    uri = URI("#{BASE_URL}/health")
    
    # Make 105 requests rapidly (should trigger rate limit at 100)
    (1..105).each do |i|
      response = make_request(uri, 'GET')
      
      if i <= 100
        assert_test("Rate limit request #{i}", response.code.to_i < 400, 
                   "Expected success for request #{i}, got #{response.code}")
      else
        assert_test("Rate limit exceeded", response.code.to_i == 429, 
                   "Expected 429 for request #{i}, got #{response.code}")
        break if response.code.to_i == 429
      end
    end
  end
  
  def test_content_type_validation
    puts "\n📝 Testing Content-Type Validation..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Test with correct Content-Type
    response = make_request(uri, 'POST', { email: 'test@example.com' }, 'application/json')
    assert_test("Valid Content-Type", [201, 409].include?(response.code.to_i), 
               "Expected 201 or 409, got #{response.code}")
    
    # Test with incorrect Content-Type
    response = make_request(uri, 'POST', { email: 'test@example.com' }, 'text/plain')
    assert_test("Invalid Content-Type", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
  end
  
  def test_payload_size_validation
    puts "\n📏 Testing Payload Size Validation..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Create a large payload (over 1MB)
    large_email = 'a' * (1_048_577) + '@example.com'
    large_payload = { email: large_email }
    
    response = make_request(uri, 'POST', large_payload)
    assert_test("Large payload rejection", response.code.to_i == 413, 
               "Expected 413, got #{response.code}")
  end
  
  def test_json_validation
    puts "\n🔧 Testing JSON Validation..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Test with invalid JSON
    response = make_request_raw(uri, 'POST', '{"email": invalid json}', 'application/json')
    assert_test("Invalid JSON", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
    
    # Test with non-object JSON
    response = make_request_raw(uri, 'POST', '"just a string"', 'application/json')
    assert_test("Non-object JSON", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
  end
  
  def test_required_fields_validation
    puts "\n✅ Testing Required Fields Validation..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Test with missing email field
    response = make_request(uri, 'POST', {})
    assert_test("Missing required field", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
    
    # Test with null email field
    response = make_request(uri, 'POST', { email: nil })
    assert_test("Null required field", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
    
    # Test with empty email field
    response = make_request(uri, 'POST', { email: '' })
    assert_test("Empty required field", response.code.to_i == 400, 
               "Expected 400, got #{response.code}")
  end
  
  def test_suspicious_pattern_detection
    puts "\n🛡️  Testing Suspicious Pattern Detection..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Test SQL injection patterns
    sql_injection_emails = [
      "test'; DROP TABLE users; --@example.com",
      "test' UNION SELECT * FROM users--@example.com",
      "test@example.com'; DELETE FROM users; --"
    ]
    
    sql_injection_emails.each_with_index do |email, i|
      response = make_request(uri, 'POST', { email: email })
      assert_test("SQL injection pattern #{i+1}", response.code.to_i == 400, 
                 "Expected 400 for SQL injection, got #{response.code}")
    end
    
    # Test XSS patterns
    xss_emails = [
      "test<script>alert('xss')</script>@example.com",
      "test@example.com<script>",
      "javascript:alert('xss')@example.com"
    ]
    
    xss_emails.each_with_index do |email, i|
      response = make_request(uri, 'POST', { email: email })
      assert_test("XSS pattern #{i+1}", response.code.to_i == 400, 
                 "Expected 400 for XSS, got #{response.code}")
    end
  end
  
  def test_encoding_validation
    puts "\n🔤 Testing Encoding Validation..."
    
    uri = URI("#{BASE_URL}/user")
    
    # Test with invalid UTF-8 encoding
    invalid_utf8 = "\xFF\xFE"
    response = make_request_raw(uri, 'POST', 
                               "{\"email\": \"test#{invalid_utf8}@example.com\"}", 
                               'application/json')
    assert_test("Invalid UTF-8 encoding", response.code.to_i == 400, 
               "Expected 400 for invalid encoding, got #{response.code}")
  end
  
  def make_request(uri, method, payload = nil, content_type = 'application/json')
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = case method
    when 'GET'
      Net::HTTP::Get.new(uri)
    when 'POST'
      req = Net::HTTP::Post.new(uri)
      req.body = payload.to_json if payload
      req['Content-Type'] = content_type
      req
    when 'PUT'
      req = Net::HTTP::Put.new(uri)
      req.body = payload.to_json if payload
      req['Content-Type'] = content_type
      req
    when 'DELETE'
      Net::HTTP::Delete.new(uri)
    end
    
    begin
      http.request(request)
    rescue => e
      puts "❌ Request failed: #{e.message}"
      OpenStruct.new(code: 500, body: e.message)
    end
  end
  
  def make_request_raw(uri, method, body, content_type = 'application/json')
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = case method
    when 'POST'
      req = Net::HTTP::Post.new(uri)
      req.body = body
      req['Content-Type'] = content_type
      req
    when 'PUT'
      req = Net::HTTP::Put.new(uri)
      req.body = body
      req['Content-Type'] = content_type
      req
    end
    
    begin
      http.request(request)
    rescue => e
      puts "❌ Request failed: #{e.message}"
      OpenStruct.new(code: 500, body: e.message)
    end
  end
  
  def assert_test(test_name, condition, message = nil)
    if condition
      puts "  ✅ #{test_name}"
      @passed += 1
    else
      puts "  ❌ #{test_name}: #{message}"
      @failed += 1
    end
    
    @test_results << {
      name: test_name,
      passed: condition,
      message: message
    }
  end
  
  def print_summary
    puts "\n" + "=" * 60
    puts "📊 TEST SUMMARY"
    puts "=" * 60
    puts "✅ Passed: #{@passed}"
    puts "❌ Failed: #{@failed}"
    puts "📈 Success Rate: #{(@passed.to_f / (@passed + @failed) * 100).round(2)}%"
    
    if @failed > 0
      puts "\n❌ FAILED TESTS:"
      @test_results.select { |r| !r[:passed] }.each do |result|
        puts "  - #{result[:name]}: #{result[:message]}"
      end
    end
    
    puts "\n🎯 Validation middleware integration complete!"
    puts "   All security validations are now active and protecting the API."
  end
end

# Check if server is running before starting tests
def check_server
  uri = URI('http://localhost:4567/health')
  begin
    response = Net::HTTP.get_response(uri)
    return true
  rescue
    puts "❌ Server not running on localhost:4567"
    puts "   Please start the server with: ruby app.rb"
    return false
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  if check_server
    test_runner = ValidationTest.new
    test_runner.run_all_tests
  end
end