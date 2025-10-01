# combinations.rb
require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"
require_relative "../lib/validation_middleware"
require_relative "../lib/app_logger"

# ------------------------------
# CREATE a new combination for a user
# POST /combinations
# Body: { "email": "user@example.com", "balls": [1,2,3,4,5], "stars": [1,2] }
# ------------------------------
post "/combinations" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    required_fields: ["email", "balls", "stars"],
    type_schema: {
      email: :email,
      balls: :array_of_integers,
      stars: :array_of_integers
    }
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status_code = case validation_result["field"]
    when "rate_limit"
      429
    when "payload_size"
      413
    when "content_type", "json_parse", "json_structure", "encoding"
      400
    else
      400
    end
    status status_code
    return validation_result.to_json
  end
  
  begin
    # Get validated payload
    payload = validation_result
    email = Validators.sanitize_email(payload["email"])
    balls = payload["balls"]
    stars = payload["stars"]

    # Additional business logic validation
    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", payload["email"], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns in email
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end

    # Enhanced lottery balls validation
    unless Validators.valid_lottery_balls?(balls)
      AppLogger.log_validation_error("balls", balls, "Invalid balls: must be exactly 5 unique integers between 1-50")
      status 400
      return Validators.validation_error("Invalid balls: must be exactly 5 unique integers between 1-50", "balls").to_json
    end

    # Enhanced lottery stars validation
    unless Validators.valid_lottery_stars?(stars)
      AppLogger.log_validation_error("stars", stars, "Invalid stars: must be exactly 2 unique integers between 1-12")
      status 400
      return Validators.validation_error("Invalid stars: must be exactly 2 unique integers between 1-12", "stars").to_json
    end
    
    AppLogger.debug("Creating combination for user: #{email}, balls: #{balls}, stars: #{stars}", "COMBINATIONS")
    # Check if user exists
    user = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])
    if user.ntuples == 0
        AppLogger.warn("Attempt to create combination for non-existent user: #{email}", "COMBINATIONS")
        status 404
        return { error: "User not found" }.to_json
    end

    existing = DB.exec_params(
        "SELECT id FROM combinations WHERE user_id = $1 AND balls = $2 AND stars = $3",
        [user[0]["id"], balls.to_json, stars.to_json]
    )
    if existing.ntuples > 0
        AppLogger.warn("Attempt to create duplicate combination for user: #{email}", "COMBINATIONS")
        status 409
        return { error: "Combination already exists for this user" }.to_json
    end
     # Insert new combination
    result = DB.exec_params(
        "INSERT INTO combinations (user_id, balls, stars) VALUES ($1, $2, $3) RETURNING id",
        [user[0]["id"], balls.to_json, stars.to_json]
    )
    combination_id = result[0]["id"]
    AppLogger.info("Combination created successfully for user: #{email}, ID: #{combination_id}", "COMBINATIONS")
    status 201
    { message: "Combination successfully added", email: email, balls: balls, stars: stars, combination_id: combination_id }.to_json

  rescue PG::Error => e
    AppLogger.log_db_error("INSERT combination", e, { email: email, balls: balls, stars: stars })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# GET all combinations of a user
# GET /combinations/:email
# ------------------------------
get "/combinations/:email" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  begin
    # Get email from Sinatra route parameter and decode it
    require 'uri'
    raw_email = params[:email]
    
    # URL decode the email parameter
    begin
      decoded_email = URI.decode_www_form_component(raw_email)
    rescue => e
      AppLogger.log_validation_error("url_decode", raw_email, "Failed to decode URL parameter: #{e.message}")
      decoded_email = raw_email
    end
    
    email = Validators.sanitize_email(decoded_email)

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", raw_email, "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    AppLogger.debug("Fetching combinations for user: #{email}", "COMBINATIONS")
    user = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])
    if user.ntuples == 0
        AppLogger.warn("Attempt to fetch combinations for non-existent user: #{email}", "COMBINATIONS")
        status 404
        return { error: "User not found" }.to_json
    end
    if user.ntuples >1
        AppLogger.error("Database inconsistency: multiple users with same email: #{email}", "COMBINATIONS")
        status 500
        return { error: "Database inconsistency: multiple users with same email" }.to_json
    end
    result = DB.exec_params("SELECT * FROM combinations WHERE user_id = $1", [user[0]["id"]])
    combinations = result.map do |row|
      {
        id: row["id"].to_i,
        balls: JSON.parse(row["balls"]),
        stars: JSON.parse(row["stars"])
      }
    end

    AppLogger.info("Fetched #{combinations.length} combinations for user: #{email}", "COMBINATIONS")
    { email: email, combinations: combinations }.to_json

  rescue PG::Error => e
    AppLogger.log_db_error("SELECT combinations", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# UPDATE a combination
# PUT /combinations/:id
# Body: { "balls": [..], "stars": [..] }
# ------------------------------
put "/combinations/:id" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    required_fields: ["balls", "stars"],
    type_schema: {
      balls: :array_of_integers,
      stars: :array_of_integers
    }
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status_code = case validation_result["field"]
    when "rate_limit"
      429
    when "payload_size"
      413
    when "content_type", "json_parse", "json_structure", "encoding"
      400
    else
      400
    end
    status status_code
    return validation_result.to_json
  end
  
  begin
    # Validate combination ID from URL parameter
    unless Validators.valid_combination_id?(params[:id])
      AppLogger.log_validation_error("id", params[:id], "Invalid combination ID")
      status 400
      return Validators.validation_error("Invalid combination ID", "id").to_json
    end

    id = params[:id].to_i
    
    # Get validated payload
    payload = validation_result
    balls = payload["balls"]
    stars = payload["stars"]

    # Enhanced lottery balls validation
    unless Validators.valid_lottery_balls?(balls)
      AppLogger.log_validation_error("balls", balls, "Invalid balls: must be exactly 5 unique integers between 1-50")
      status 400
      return Validators.validation_error("Invalid balls: must be exactly 5 unique integers between 1-50", "balls").to_json
    end

    # Enhanced lottery stars validation
    unless Validators.valid_lottery_stars?(stars)
      AppLogger.log_validation_error("stars", stars, "Invalid stars: must be exactly 2 unique integers between 1-12")
      status 400
      return Validators.validation_error("Invalid stars: must be exactly 2 unique integers between 1-12", "stars").to_json
    end

    AppLogger.debug("Updating combination ID: #{id}, balls: #{balls}, stars: #{stars}", "COMBINATIONS")
    user = DB.exec_params(
        "SELECT user_id FROM combinations WHERE id = $1",
        [id]
    )
    if user.ntuples > 0
        user_id = user[0]["user_id"]
    else
        AppLogger.warn("Attempt to update non-existent combination: #{id}", "COMBINATIONS")
        status 404
        return { error: "Combination not found" }.to_json
    end

    existing = DB.exec_params(
        "SELECT id FROM combinations WHERE user_id = $1 AND balls = $2 AND stars = $3",
        [user_id, balls.to_json, stars.to_json]
    )
    if existing.ntuples > 0
        AppLogger.warn("Attempt to update to duplicate combination for user_id: #{user_id}", "COMBINATIONS")
        status 409
        return { error: "Combination already exists for this user" }.to_json
    end

    result = DB.exec_params(
      "UPDATE combinations SET balls = $1, stars = $2 WHERE id = $3",
      [balls.to_json, stars.to_json, id]
    )

    if result.cmd_tuples.zero?
      AppLogger.warn("Attempt to update non-existent combination: #{id}", "COMBINATIONS")
      status 404
      { error: "Combination not found" }.to_json
    else
      AppLogger.info("Combination updated successfully: ID #{id}", "COMBINATIONS")
      { message: "Combination updated", id: id, balls: balls, stars: stars }.to_json
    end

  rescue PG::Error => e
    AppLogger.log_db_error("UPDATE combination", e, { id: id, balls: balls, stars: stars })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# DELETE a combination
# DELETE /combinations/:id
# ------------------------------
delete "/combinations/:id" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  begin
    # Validate combination ID from URL parameter
    unless Validators.valid_combination_id?(params[:id])
      AppLogger.log_validation_error("id", params[:id], "Invalid combination ID")
      status 400
      return Validators.validation_error("Invalid combination ID", "id").to_json
    end

    id = params[:id].to_i

    AppLogger.debug("Deleting combination ID: #{id}", "COMBINATIONS")
    result = DB.exec_params("DELETE FROM combinations WHERE id = $1", [id])

    if result.cmd_tuples.zero?
      AppLogger.warn("Attempt to delete non-existent combination: #{id}", "COMBINATIONS")
      status 404
      { error: "Combination not found" }.to_json
    else
      AppLogger.info("Combination deleted successfully: ID #{id}", "COMBINATIONS")
      { message: "Combination deleted", id: id }.to_json
    end

  rescue PG::Error => e
    AppLogger.log_db_error("DELETE combination", e, { id: id })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
