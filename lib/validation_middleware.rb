# Centralized validation middleware for enhanced security and data validation

require 'json'
require 'sinatra/base'
require_relative 'app_logger'

module ValidationMiddleware

  MAX_PAYLOAD_SIZE = 1_048_576

  @@rate_limit_store = {}
  @@rate_limit_window = 60 
  @@rate_limit_max_requests = 10 

  def self.validate_content_type(request)
    content_type = request.content_type

    return true if ['GET', 'DELETE'].include?(request.request_method)
    
    unless content_type&.include?('application/json')
      AppLogger.log_validation_error("content_type", content_type, "Invalid Content-Type, expected application/json")
      return {
        error: "Invalid Content-Type",
        details: "Expected 'application/json', got '#{content_type}'",
        field: "content_type"
      }
    end
    
    true
  end

  def self.validate_payload_size(request)
    return true if ['GET', 'DELETE'].include?(request.request_method)
    
    content_length = request.content_length

    begin
      content_length_int = content_length.to_i if content_length
      if content_length_int && content_length_int > MAX_PAYLOAD_SIZE
        AppLogger.log_validation_error("payload_size", content_length_int, "Payload too large")
        return {
          error: "Payload too large",
          details: "Maximum allowed size is #{MAX_PAYLOAD_SIZE} bytes",
          field: "payload_size"
        }
      end
    rescue => e

      AppLogger.log_validation_error("payload_size", content_length, "Invalid content length format: #{e.message}")
    end
    
    true
  end

  def self.validate_rate_limit(request)
    client_ip = request.ip
    current_time = Time.now.to_i
    window_start = current_time - @@rate_limit_window

    @@rate_limit_store[client_ip] ||= []
    @@rate_limit_store[client_ip].reject! { |timestamp| timestamp < window_start }

    if @@rate_limit_store[client_ip].length >= @@rate_limit_max_requests
      AppLogger.log_validation_error("rate_limit", client_ip, "Rate limit exceeded")
      return {
        error: "Rate limit exceeded",
        details: "Maximum #{@@rate_limit_max_requests} requests per #{@@rate_limit_window} seconds",
        field: "rate_limit"
      }
    end

    @@rate_limit_store[client_ip] << current_time
    true
  end

  def self.parse_json_safely(body_string)
    return {} if body_string.nil? || body_string.strip.empty?

    unless body_string.valid_encoding?
      AppLogger.log_validation_error("encoding", "invalid", "Invalid character encoding")
      return {
        error: "Invalid character encoding",
        details: "Request body contains invalid UTF-8 characters",
        field: "encoding"
      }
    end
    
    begin
      parsed = JSON.parse(body_string)

      unless parsed.is_a?(Hash)
        AppLogger.log_validation_error("json_structure", parsed.class, "JSON must be an object")
        return {
          error: "Invalid JSON structure",
          details: "Expected JSON object, got #{parsed.class}",
          field: "json_structure"
        }
      end
      
      parsed
    rescue JSON::ParserError => e
      AppLogger.log_validation_error("json_parse", e.message, "Invalid JSON format")
      {
        error: "Invalid JSON format",
        details: e.message,
        field: "json_parse"
      }
    end
  end

  def self.validate_required_fields(payload, required_fields)
    return true if payload.is_a?(Hash) && payload.key?("error")
    
    missing_fields = []
    
    required_fields.each do |field|
      if !payload.key?(field) || payload[field].nil? || 
         (payload[field].is_a?(String) && payload[field].strip.empty?)
        missing_fields << field
      end
    end
    
    unless missing_fields.empty?
      AppLogger.log_validation_error("required_fields", missing_fields, "Missing required fields")
      return {
        error: "Missing required fields",
        details: "The following fields are required: #{missing_fields.join(', ')}",
        field: "required_fields",
        missing_fields: missing_fields
      }
    end
    
    true
  end

  def self.validate_data_types(payload, type_schema)
    return true if payload.is_a?(Hash) && payload.key?("error")
    
    type_errors = []
    
    type_schema.each do |field, expected_type|
      next unless payload.key?(field)
      
      value = payload[field]
      valid = case expected_type
      when :string
        value.is_a?(String)
      when :integer
        value.is_a?(Integer)
      when :array
        value.is_a?(Array)
      when :email
        value.is_a?(String) && value.match?(/\A[\w+.-]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i)
      when :array_of_integers
        value.is_a?(Array) && value.all? { |v| v.is_a?(Integer) }
      else
        true 
      end
      
      unless valid
        type_errors << "#{field} must be #{expected_type}"
      end
    end
    
    unless type_errors.empty?
      AppLogger.log_validation_error("data_types", type_errors, "Invalid data types")
      return {
        error: "Invalid data types",
        details: type_errors.join(', '),
        field: "data_types",
        type_errors: type_errors
      }
    end
    
    true
  end

  def self.sanitize_url_params(params)
    require 'uri'
    sanitized = {}
    
    params.each do |key, value|
      next if value.nil?

      begin
        decoded_value = URI.decode_www_form_component(value.to_s)
      rescue => e
        AppLogger.log_validation_error("url_decode", key, "Failed to decode URL parameter: #{e.message}")
        decoded_value = value.to_s
      end

      clean_value = decoded_value.strip

      clean_value = clean_value.gsub(/[<>'"&]/, '')

      if clean_value.valid_encoding?
        sanitized[key] = clean_value
      else
        AppLogger.log_validation_error("url_param_encoding", key, "Invalid encoding in URL parameter")
        sanitized[key] = clean_value.encode('UTF-8', invalid: :replace, undef: :replace)
      end
    end
    
    sanitized
  end

  def self.validate_headers(request)

    user_agent = request.env['HTTP_USER_AGENT']
    
    if user_agent.nil? || user_agent.strip.empty?
      AppLogger.log_validation_error("user_agent", "missing", "Missing User-Agent header")

    end

    if user_agent && user_agent.length > 1000
      AppLogger.log_validation_error("user_agent", "too_long", "Suspiciously long User-Agent header")
    end
    
    true
  end

  def self.validate_request(request, options = {})

    required_fields = options[:required_fields] || []
    type_schema = options[:type_schema] || {}
    skip_content_type = options[:skip_content_type] || false
    
    rate_limit_result = validate_rate_limit(request)
    return rate_limit_result unless rate_limit_result == true
    
    validate_headers(request)

    unless skip_content_type
      content_type_result = validate_content_type(request)
      return content_type_result unless content_type_result == true
    end

    payload_size_result = validate_payload_size(request)
    return payload_size_result unless payload_size_result == true

    if ['POST', 'PUT'].include?(request.request_method)
      body_string = request.body.read
      request.body.rewind
      
      parsed_payload = parse_json_safely(body_string)
      return parsed_payload if parsed_payload.is_a?(Hash) && parsed_payload.key?("error")

      unless required_fields.empty?
        required_fields_result = validate_required_fields(parsed_payload, required_fields)
        return required_fields_result unless required_fields_result == true
      end

      unless type_schema.empty?
        data_types_result = validate_data_types(parsed_payload, type_schema)
        return data_types_result unless data_types_result == true
      end
      
      return parsed_payload
    end
    sanitize_url_params(request.params)
  end
end