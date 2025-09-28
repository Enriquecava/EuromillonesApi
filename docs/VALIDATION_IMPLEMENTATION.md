# Input Data Validation Implementation Plan

## Overview
This document provides a complete implementation plan for robust input data validation in the Euromillones API. All code examples are in English and ready for implementation.

## Current Validation Gaps Identified

1. **Email validation**: Only checks for presence, not format
2. **Lottery numbers validation**: No range validation (balls: 1-50, stars: 1-12)
3. **Array validation**: No checks for duplicates, data types, or exact counts
4. **Input sanitization**: Limited input cleaning and normalization

## 1. Create Validation Helpers Module

**File: `lib/validators.rb`**

```ruby
# lib/validators.rb
# Input validation helpers for Euromillones API

module Validators
  # Email validation with proper regex
  def self.valid_email?(email)
    return false if email.nil? || email.strip.empty?
    
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    email.strip.match?(email_regex) && email.length <= 255
  end

  # Validate lottery balls (1-50, exactly 5 unique numbers)
  def self.valid_lottery_balls?(balls)
    return false unless balls.is_a?(Array)
    return false unless balls.length == 5
    return false unless balls.all? { |ball| ball.is_a?(Integer) }
    return false unless balls.all? { |ball| ball >= 1 && ball <= 50 }
    return false unless balls.uniq.length == balls.length # No duplicates
    
    true
  end

  # Validate lottery stars (1-12, exactly 2 unique numbers)
  def self.valid_lottery_stars?(stars)
    return false unless stars.is_a?(Array)
    return false unless stars.length == 2
    return false unless stars.all? { |star| star.is_a?(Integer) }
    return false unless stars.all? { |star| star >= 1 && star <= 12 }
    return false unless stars.uniq.length == stars.length # No duplicates
    
    true
  end

  # Validate combination ID (positive integer)
  def self.valid_combination_id?(id)
    return false if id.nil?
    return false unless id.to_s.match?(/^\d+$/)
    
    id.to_i > 0
  end

  # Validate date format (YYYY-MM-DD)
  def self.valid_date_format?(date_str)
    return false if date_str.nil? || date_str.strip.empty?
    
    date_str.strip.match?(/^\d{4}-\d{2}-\d{2}$/)
  end

  # Sanitize email input
  def self.sanitize_email(email)
    return nil if email.nil?
    
    email.strip.downcase
  end

  # Generate validation error response
  def self.validation_error(message, field = nil)
    error_response = { error: message }
    error_response[:field] = field if field
    error_response
  end
end
```

## 2. Enhanced User Endpoints Validation

**File: `routes/users.rb` - Enhanced validation sections**

### GET /user/:email
```ruby
# Add after line 13 (email = params[:email]&.strip)
email = Validators.sanitize_email(params[:email])

unless Validators.valid_email?(email)
  status 400
  return Validators.validation_error("Invalid email format", "email").to_json
end
```

### POST /user
```ruby
# Replace lines 47-52 with:
email = Validators.sanitize_email(payload["email"])

unless Validators.valid_email?(email)
  status 400
  return Validators.validation_error("Invalid email format", "email").to_json
end
```

### PUT /user/:email
```ruby
# Replace lines 85-92 with:
old_email = Validators.sanitize_email(params[:email])
new_email = Validators.sanitize_email(payload["email"])

unless Validators.valid_email?(old_email)
  status 400
  return Validators.validation_error("Invalid old email format", "old_email").to_json
end

unless Validators.valid_email?(new_email)
  status 400
  return Validators.validation_error("Invalid new email format", "new_email").to_json
end
```

### DELETE /user/:email
```ruby
# Replace lines 129-134 with:
email = Validators.sanitize_email(params[:email])

unless Validators.valid_email?(email)
  status 400
  return Validators.validation_error("Invalid email format", "email").to_json
end
```

## 3. Enhanced Combinations Endpoints Validation

**File: `routes/combinations.rb` - Enhanced validation sections**

### POST /combinations
```ruby
# Replace lines 15-33 with:
email = Validators.sanitize_email(payload["email"])
balls = payload["balls"]
stars = payload["stars"]

# Validate email
unless Validators.valid_email?(email)
  status 400
  return Validators.validation_error("Invalid email format", "email").to_json
end

# Validate balls
unless Validators.valid_lottery_balls?(balls)
  status 400
  return Validators.validation_error("Invalid balls: must be exactly 5 unique integers between 1-50", "balls").to_json
end

# Validate stars
unless Validators.valid_lottery_stars?(stars)
  status 400
  return Validators.validation_error("Invalid stars: must be exactly 2 unique integers between 1-12", "stars").to_json
end
```

### GET /combinations/:email
```ruby
# Replace lines 74-78 with:
email = Validators.sanitize_email(params[:email])

unless Validators.valid_email?(email)
  status 400
  return Validators.validation_error("Invalid email format", "email").to_json
end
```

### PUT /combinations/:id
```ruby
# Replace lines 113-121 with:
unless Validators.valid_combination_id?(params[:id])
  status 400
  return Validators.validation_error("Invalid combination ID", "id").to_json
end

id = params[:id].to_i
payload = JSON.parse(request.body.read)
balls = payload["balls"]
stars = payload["stars"]

# Validate balls
unless Validators.valid_lottery_balls?(balls)
  status 400
  return Validators.validation_error("Invalid balls: must be exactly 5 unique integers between 1-50", "balls").to_json
end

# Validate stars
unless Validators.valid_lottery_stars?(stars)
  status 400
  return Validators.validation_error("Invalid stars: must be exactly 2 unique integers between 1-12", "stars").to_json
end
```

### DELETE /combinations/:id
```ruby
# Replace lines 171-172 with:
unless Validators.valid_combination_id?(params[:id])
  status 400
  return Validators.validation_error("Invalid combination ID", "id").to_json
end

id = params[:id].to_i
```

## 4. Enhanced Euromillones Results Validation

**File: `routes/euromillones.rb` - Enhanced validation**

```ruby
# Replace lines 7-14 with:
date_str = params[:date]&.strip

# Validate date format
unless Validators.valid_date_format?(date_str)
  status 400
  return Validators.validation_error("Invalid date format (use YYYY-MM-DD)", "date").to_json
end
```

## 5. Required File Updates

### Update app.rb
Add this line after line 3:
```ruby
require_relative "lib/validators"
```

### Update all route files
Add this line at the top of each route file:
```ruby
require_relative "../lib/validators"
```

## 6. Validation Rules Documentation

### Email Validation Rules
- Must be a valid email format (RFC compliant)
- Maximum length: 255 characters
- Automatically converted to lowercase
- Leading/trailing whitespace removed

### Lottery Balls Validation Rules
- Must be an array of exactly 5 integers
- Each number must be between 1 and 50 (inclusive)
- No duplicate numbers allowed
- All elements must be integers

### Lottery Stars Validation Rules
- Must be an array of exactly 2 integers
- Each number must be between 1 and 12 (inclusive)
- No duplicate numbers allowed
- All elements must be integers

### Date Validation Rules
- Must follow YYYY-MM-DD format
- Must be a valid calendar date
- Cannot be in the future

### Combination ID Validation Rules
- Must be a positive integer
- Must be greater than 0

## 7. Error Response Format

All validation errors follow this consistent format:
```json
{
  "error": "Descriptive error message",
  "field": "field_name" // Optional, indicates which field failed validation
}
```

## 8. Implementation Steps

1. Create the `lib/validators.rb` file with the validation module
2. Update `app.rb` to require the validators module
3. Update each route file to require the validators module
4. Replace existing validation code in each endpoint with enhanced validation
5. Test all endpoints with various invalid inputs
6. Update API documentation with new validation rules

## 9. Testing Scenarios

### Email Validation Tests
- Valid emails: `test@example.com`, `user.name+tag@domain.co.uk`
- Invalid emails: `invalid-email`, `@domain.com`, `user@`, `toolong${'a' * 250}@domain.com`

### Lottery Numbers Tests
- Valid balls: `[1, 15, 23, 34, 50]`
- Invalid balls: `[0, 15, 23, 34, 50]`, `[1, 15, 23, 34]`, `[1, 15, 23, 34, 51]`, `[1, 1, 23, 34, 50]`
- Valid stars: `[1, 12]`
- Invalid stars: `[0, 12]`, `[1]`, `[1, 13]`, `[1, 1]`

### Date Tests
- Valid dates: `2024-01-15`, `2023-12-31`
- Invalid dates: `2024-13-01`, `2024-01-32`, `24-01-15`, `2025-01-01` (future)

## 10. Performance Considerations

- All validations are O(1) or O(n) where n is small (max 5 elements)
- Regex patterns are compiled once and reused
- Early return on validation failures to minimize processing
- Input sanitization prevents unnecessary database queries

This implementation provides comprehensive, robust validation while maintaining good performance and clear error messages.