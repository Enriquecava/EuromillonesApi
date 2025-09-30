require "sinatra"
require "json"
require "date"
require_relative "../db"
require_relative "../lib/validators"
require_relative "../lib/validation_middleware"
require_relative "../lib/app_logger"

# GET result by date (YYYY-MM-DD)
get "/results/:date" do
  # Apply validation middleware (but handle route params separately)
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  # For route parameters, we need to sanitize them manually since
  # request.params doesn't include route params, only query params
  sanitized_params = ValidationMiddleware.sanitize_url_params(params)
  date_str = sanitized_params["date"]&.strip

  # Validate date format
  unless Validators.valid_date_format?(date_str)
    AppLogger.log_validation_error("date", sanitized_params["date"], "Invalid date format (use YYYY-MM-DD)")
    status 400
    return Validators.validation_error("Invalid date format (use YYYY-MM-DD)", "date").to_json
  end
  
  # Check for suspicious patterns in date parameter
  if Validators.contains_suspicious_patterns?(date_str)
    AppLogger.log_validation_error("date", date_str, "Suspicious patterns detected in date parameter")
    status 400
    return Validators.validation_error("Invalid date format (use YYYY-MM-DD)", "date").to_json
  end

  begin
    # Check if it's a real date
    date = Date.strptime(date_str, "%Y-%m-%d")
  rescue ArgumentError
    AppLogger.log_validation_error("date", date_str, "Invalid date (day or month does not exist)")
    status 400
    return { error: "Invalid date (day or month does not exist)" }.to_json
  end

  # Check if it's in the future
  if date > Date.today
    AppLogger.log_validation_error("date", date_str, "Date cannot be in the future")
    status 400
    return { error: "Date cannot be in the future" }.to_json
  end

  # Check if it's a valid Euromillones draw day (Tuesday or Friday)
  unless Validators.valid_euromillones_draw_day?(date_str)
    day_name = date.strftime("%A")
    AppLogger.log_validation_error("date", date_str, "#{day_name} is not a Euromillones draw day")
    status 400
    return { error: "No Euromillones draw on #{day_name}. Draws are held on Tuesdays and Fridays only." }.to_json
  end

  AppLogger.debug("Searching for lottery result: #{date_str}", "RESULTS")
  # Search in database
  begin
    row = DB.exec_params("SELECT * FROM results WHERE date = $1", [date_str]).first

    if row
      AppLogger.info("Lottery result found for date: #{date_str}", "RESULTS")
      {
        date: row["date"],
        balls: JSON.parse(row["bolas"]),
        stars: JSON.parse(row["stars"]),
        jackpot: JSON.parse(row["jackpot"])
      }.to_json
    else
      AppLogger.warn("No lottery result found for date: #{date_str}", "RESULTS")
      status 404
      { error: "No result found for this date" }.to_json
    end
  rescue PG::Error => e
    AppLogger.log_db_error("SELECT result", e, { date: date_str })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
