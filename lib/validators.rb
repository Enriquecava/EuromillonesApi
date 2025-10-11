# lib/validators.rb
# Enhanced input validation helpers for Euromillones API

require_relative 'app_logger'

module Validators
  def self.valid_email?(email)
    return false if email.nil? || email.strip.empty?

    return false if email.length > 255 || email.length < 5

    email_regex = /\A[\w+\.-]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
    clean_email = email.strip.downcase

    return false unless clean_email.match?(email_regex)

    return false if clean_email.include?('..') # No consecutive dots
    return false if clean_email.start_with?('.') || clean_email.end_with?('.')
    return false if clean_email.include?('@.') || clean_email.include?('.@')

    suspicious_chars = ['<', '>', '"', "'", '&', ';', '(', ')', '{', '}', '[', ']']
    return false if suspicious_chars.any? { |char| clean_email.include?(char) }
    
    true
  end

  def self.valid_lottery_balls?(balls)
    return false unless balls.is_a?(Array)
    return false unless balls.length == 5

    balls.each_with_index do |ball, index|
      unless ball.is_a?(Integer)
        AppLogger.log_validation_error("balls[#{index}]", ball, "Ball must be an integer")
        return false
      end
      
      unless ball >= 1 && ball <= 50
        AppLogger.log_validation_error("balls[#{index}]", ball, "Ball must be between 1 and 50")
        return false
      end
    end
    
    # Check for duplicates
    unless balls.uniq.length == balls.length
      duplicates = balls.select { |ball| balls.count(ball) > 1 }.uniq
      AppLogger.log_validation_error("balls", duplicates, "Duplicate balls found")
      return false
    end
    
    true
  end

  def self.valid_lottery_stars?(stars)
    return false unless stars.is_a?(Array)
    return false unless stars.length == 2

    stars.each_with_index do |star, index|
      unless star.is_a?(Integer)
        AppLogger.log_validation_error("stars[#{index}]", star, "Star must be an integer")
        return false
      end
      
      unless star >= 1 && star <= 12
        AppLogger.log_validation_error("stars[#{index}]", star, "Star must be between 1 and 12")
        return false
      end
    end

    unless stars.uniq.length == stars.length
      duplicates = stars.select { |star| stars.count(star) > 1 }.uniq
      AppLogger.log_validation_error("stars", duplicates, "Duplicate stars found")
      return false
    end
    
    true
  end

  def self.valid_combination_id?(id)
    return false if id.nil?

    return false unless id.to_s.match?(/^\d+$/)

    id_int = id.to_i
    return false unless id_int > 0
    return false if id_int > 2147483647 
    
    true
  end

  def self.valid_date_format?(date_str)
    return false if date_str.nil? || date_str.strip.empty?
    
    clean_date = date_str.strip

    return false unless clean_date.match?(/^\d{4}-\d{2}-\d{2}$/)

    year, month, day = clean_date.split('-').map(&:to_i)

    return false unless year >= 1900 && year <= 2100
    return false unless month >= 1 && month <= 12
    return false unless day >= 1 && day <= 31
    
    true
  end

  def self.valid_euromillones_draw_day?(date_str)
    return false if date_str.nil? || date_str.strip.empty?
    
    begin
      date = Date.strptime(date_str, "%Y-%m-%d")
      draw_days = [2, 5]
      draw_days.include?(date.wday)
    rescue ArgumentError
      false
    end
  end

  def self.sanitize_email(email)
    return nil if email.nil?

    require 'uri'
    decoded_email = URI.decode_www_form_component(email.to_s)

    clean_email = decoded_email.strip.downcase

    clean_email = clean_email.gsub(/[<>"'&;(){}]|[\[\]]/, '')

    unless clean_email.valid_encoding?
      clean_email = clean_email.encode('UTF-8', invalid: :replace, undef: :replace)
    end
    
    clean_email
  end

  def self.validation_error(message, field = nil, details = nil)
    error_response = { error: message }
    error_response[:field] = field if field
    error_response[:details] = details if details
    error_response[:timestamp] = Time.now.iso8601
    error_response
  end

  def self.valid_json_structure?(payload, required_structure)
    return false unless payload.is_a?(Hash)
    
    required_structure.each do |key, type|
      return false unless payload.key?(key.to_s)
      
      value = payload[key.to_s]
      case type
      when :string
        return false unless value.is_a?(String)
      when :integer
        return false unless value.is_a?(Integer)
      when :array
        return false unless value.is_a?(Array)
      when :email
        return false unless valid_email?(value)
      end
    end
    
    true
  end

  def self.sanitize_hash_strings(hash)
    return hash unless hash.is_a?(Hash)
    
    sanitized = {}
    hash.each do |key, value|
      sanitized_key = key.to_s.strip
      
      if value.is_a?(String)

        sanitized_value = value.strip.gsub(/[<>"'&;]/, '')

        sanitized_value = sanitized_value.encode('UTF-8', invalid: :replace, undef: :replace) unless sanitized_value.valid_encoding?
        sanitized[sanitized_key] = sanitized_value
      else
        sanitized[sanitized_key] = value
      end
    end
    
    sanitized
  end

  def self.valid_integer_array?(array, min_val, max_val, exact_length = nil)
    return false unless array.is_a?(Array)
    return false if exact_length && array.length != exact_length
    
    array.all? do |item|
      item.is_a?(Integer) && item >= min_val && item <= max_val
    end
  end

  def self.contains_suspicious_patterns?(input)
    return false if input.nil?
    
    input_str = input.to_s.downcase

    sql_patterns = ['union', 'select', 'drop', 'delete', 'insert', 'update', '--', ';']
    return true if sql_patterns.any? { |pattern| input_str.include?(pattern) }

    xss_patterns = ['<script', 'javascript:', 'onload=', 'onerror=', 'onclick=']
    return true if xss_patterns.any? { |pattern| input_str.include?(pattern) }

    return true if input_str.include?('../') || input_str.include?('..\\')
    
    false
  end
end