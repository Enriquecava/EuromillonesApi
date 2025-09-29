# users.rb
require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"
require_relative "../lib/validation_middleware"
require_relative "../lib/app_logger"

# ------------------------------
# GET user deletion preview
# GET /user/:email/delete-preview
# Shows what will be deleted before actual deletion
# ------------------------------
get "/user/:email/delete-preview" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  email = nil
  begin
    # Get sanitized parameters
    sanitized_params = validation_result
    email = Validators.sanitize_email(sanitized_params["email"])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", sanitized_params["email"], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end

    AppLogger.debug("Generating deletion preview for user: #{email}", "USERS")
    
    # Check if user exists and get user info
    user_result = DB.exec_params("SELECT id FROM users WHERE email = $1", [email])
    
    if user_result.ntuples.zero?
      AppLogger.warn("Deletion preview requested for non-existent user: #{email}", "USERS")
      status 404
      return { error: "User not found" }.to_json
    end
    
    user_id = user_result[0]["id"]
    
    # Count associated combinations
    combinations_result = DB.exec_params(
      "SELECT COUNT(*) as count FROM combinations WHERE user_id = $1",
      [user_id]
    )
    combinations_count = combinations_result[0]["count"].to_i
    
    AppLogger.info("Deletion preview generated for user: #{email}, #{combinations_count} combinations will be deleted", "USERS")
    
    {
      email: email,
      user_id: user_id.to_i,
      combinations_to_delete: combinations_count,
      warning: "Deleting this user will permanently remove all associated combinations",
      cascade_info: "This operation uses database CASCADE constraints for referential integrity"
    }.to_json

  rescue PG::Error => e
    AppLogger.log_db_error("DELETE preview", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# GET user by email
# GET /user/:email
# ------------------------------
get "/user/:email" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  email = nil
  begin
    # Get sanitized parameters
    sanitized_params = validation_result
    email = Validators.sanitize_email(sanitized_params["email"])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", sanitized_params["email"], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end

    AppLogger.debug("Looking up user: #{email}", "USERS")
    result = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])

    if result.ntuples.zero?
      AppLogger.info("User not found: #{email}", "USERS")
      status 404
      { error: "User not found" }.to_json
    else
      user = result[0]
      AppLogger.info("User found: #{email}", "USERS")
      { email: user["email"],
        user_id: user["id"]}.to_json
    end

  rescue PG::Error => e
    AppLogger.log_db_error("SELECT user", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# CREATE user
# POST /user
# Body: { "email": "user@example.com" }
# Ensures only one user per email
# ------------------------------
post "/user" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    required_fields: ["email"],
    type_schema: { email: :email }
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
  
  email = nil
  begin
    # Get validated payload
    payload = validation_result
    email = Validators.sanitize_email(payload["email"])

    # Additional business logic validation
    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", payload["email"], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    AppLogger.debug("Creating user: #{email}", "USERS")
    
    # Use INSERT with ON CONFLICT to handle duplicates atomically
    result = DB.exec_params(
      "INSERT INTO users (email) VALUES ($1) ON CONFLICT (email) DO NOTHING RETURNING id",
      [email]
    )

    if result.ntuples.zero?
      AppLogger.warn("Attempt to create existing user: #{email}", "USERS")
      status 409
      return { error: "Email already exists" }.to_json
    end

    AppLogger.info("User created successfully: #{email}", "USERS")
    status 201
    { message: "User created", email: email }.to_json

  rescue PG::Error => e
    AppLogger.log_db_error("INSERT user", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# UPDATE user email
# PUT /user/:email
# Body: { "email": "new@example.com" }
# ------------------------------
put "/user/:email" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    required_fields: ["email"],
    type_schema: { email: :email }
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
  
  old_email = nil
  new_email = nil
  begin
    # Get validated payload and sanitized params
    payload = validation_result
    old_email = Validators.sanitize_email(params[:email])
    new_email = Validators.sanitize_email(payload["email"])

    unless Validators.valid_email?(old_email)
      AppLogger.log_validation_error("old_email", params[:email], "Invalid old email format")
      status 400
      return Validators.validation_error("Invalid old email format", "old_email").to_json
    end

    unless Validators.valid_email?(new_email)
      AppLogger.log_validation_error("new_email", payload["email"], "Invalid new email format")
      status 400
      return Validators.validation_error("Invalid new email format", "new_email").to_json
    end
    
    # Check for suspicious patterns in both emails
    if Validators.contains_suspicious_patterns?(old_email) || Validators.contains_suspicious_patterns?(new_email)
      AppLogger.log_validation_error("email", "#{old_email} -> #{new_email}", "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    AppLogger.debug("Updating user email: #{old_email} -> #{new_email}", "USERS")
    
    # Use UPDATE with proper error handling for constraints
    result = DB.exec_params(
      "UPDATE users SET email = $1 WHERE email = $2",
      [new_email, old_email]
    )
    
    if result.cmd_tuples.zero?
      AppLogger.warn("Attempt to update non-existent user: #{old_email}", "USERS")
      status 404
      return { error: "User not found" }.to_json
    end
    
    AppLogger.info("User email updated successfully: #{old_email} -> #{new_email}", "USERS")
    { message: "User email updated", old_email: old_email, new_email: new_email }.to_json

  rescue PG::UniqueViolation
    AppLogger.warn("Unique violation when updating user email: #{old_email || 'unknown'} -> #{new_email || 'unknown'}", "USERS")
    status 409
    { error: "New email already exists" }.to_json
  rescue PG::Error => e
    AppLogger.log_db_error("UPDATE user", e, { old_email: old_email, new_email: new_email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# DELETE user
# DELETE /user/:email
# Deletes a user by email with referential integrity validation
# ------------------------------
delete "/user/:email" do
  content_type :json
  
  # Apply validation middleware
  validation_result = ValidationMiddleware.validate_request(request, {
    skip_content_type: true
  })
  
  if validation_result.is_a?(Hash) && validation_result.key?("error")
    status 400
    return validation_result.to_json
  end
  
  email = nil
  begin
    # Get sanitized parameters
    sanitized_params = validation_result
    email = Validators.sanitize_email(sanitized_params["email"])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", sanitized_params["email"], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    
    # Check for suspicious patterns
    if Validators.contains_suspicious_patterns?(email)
      AppLogger.log_validation_error("email", email, "Suspicious patterns detected in email")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end

    AppLogger.debug("Deleting user: #{email}", "USERS")
    
    # First, get user info and count combinations for logging
    user_result = DB.exec_params("SELECT id FROM users WHERE email = $1", [email])
    
    if user_result.ntuples.zero?
      AppLogger.warn("Attempt to delete non-existent user: #{email}", "USERS")
      status 404
      return { error: "User not found" }.to_json
    end
    
    user_id = user_result[0]["id"]
    
    # Count combinations before deletion for detailed logging
    combinations_result = DB.exec_params(
      "SELECT COUNT(*) as count FROM combinations WHERE user_id = $1",
      [user_id]
    )
    combinations_count = combinations_result[0]["count"].to_i
    
    # Delete user (combinations will be deleted by CASCADE constraint)
    delete_result = DB.exec_params("DELETE FROM users WHERE email = $1", [email])
    
    if delete_result.cmd_tuples.zero?
      AppLogger.warn("Unexpected: user disappeared during deletion: #{email}", "USERS")
      status 404
      { error: "User not found" }.to_json
    else
      AppLogger.info("User deleted successfully: #{email} (#{combinations_count} combinations also deleted by CASCADE)", "USERS")
      {
        message: "User deleted successfully",
        email: email,
        combinations_deleted: combinations_count,
        referential_integrity: "Maintained via database CASCADE constraints"
      }.to_json
    end

  rescue PG::Error => e
    AppLogger.log_db_error("DELETE user", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
