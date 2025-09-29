# lib/validators.rb
# Input validation helpers for Euromillones API

module Validators
  # Email validation with proper regex
  def self.valid_email?(email)
    return false if email.nil? || email.strip.empty?
    
    email_regex = /\A[\w+.-]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
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