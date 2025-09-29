require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"
require_relative "../lib/validation_middleware"
require_relative "../lib/app_logger"


# Home endpoint: info about the API
get "/" do
  content_type :json
  
  # Apply validation middleware (basic rate limiting and header validation)
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status_code = case validation_result["field"]
    when "rate_limit"
      429
    else
      400
    end
    status status_code
    return validation_result.to_json
  end
  
  AppLogger.debug("API info endpoint accessed", "SYSTEM")
  {
    api: "Euromillones Results API",
    version: "1.0",
    endpoints: {
      get_result: "/results/:date  (YYYY-MM-DD)",
      add_user: "/user  (POST JSON)",
      get_user: "/user/:email (GET)",
      update_user: "/user/:email (PUT)",
      delete_user: "/user/:email (DELETE)",
      add_combination: "/combinations (POST JSON)",
      get_combinations: "/combinations/:email (GET)",
      update_combination: "/combinations/:id (PUT)",
      delete_combination: "/combinations/:id (DELETE)",
      health: "/health"
    },
    description: "This API allows you to query Euromillones results, manage users and their combinations.",
    security_features: [
      "Rate limiting",
      "Input validation",
      "Content-Type validation",
      "Payload size limits",
      "Encoding validation",
      "Suspicious pattern detection"
    ]
  }.to_json
end

# Health check endpoint
get "/health" do
  content_type :json

  # Apply validation middleware (basic rate limiting and header validation)
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status_code = case validation_result["field"]
    when "rate_limit"
      429
    else
      400
    end
    status status_code
    return validation_result.to_json
  end

  AppLogger.debug("Health check requested", "SYSTEM")
  begin
    # Simple DB query to check if database is reachable
    DB.exec_params("SELECT 1")
    AppLogger.info("Health check passed - database is reachable", "SYSTEM")
    status 200
    {
      status: "OK",
      message: "API is live and database is reachable",
      timestamp: Time.now.iso8601,
      validation_middleware: "active"
    }.to_json
  rescue StandardError => e
    AppLogger.error("Health check failed - database unreachable: #{e.message}", "SYSTEM")
    status 500
    {
      status: "ERROR",
      message: "API is down or database is unreachable",
      error: e.message,
      timestamp: Time.now.iso8601
    }.to_json
  end
end

