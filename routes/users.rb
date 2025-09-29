# users.rb
require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"
require_relative "../lib/app_logger"

# ------------------------------
# GET user by email
# GET /user/:email
# ------------------------------
get "/user/:email" do
  content_type :json
  email = nil
  begin
    email = Validators.sanitize_email(params[:email])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", params[:email], "Invalid email format")
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
  email = nil
  begin
    payload = JSON.parse(request.body.read)
    email = Validators.sanitize_email(payload["email"])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", payload["email"], "Invalid email format")
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

  rescue JSON::ParserError
    AppLogger.warn("Invalid JSON in user creation request", "USERS")
    status 400
    { error: "Invalid JSON" }.to_json
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
  old_email = nil
  new_email = nil
  begin
    old_email = Validators.sanitize_email(params[:email])
    payload = JSON.parse(request.body.read)
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
  rescue JSON::ParserError
    AppLogger.warn("Invalid JSON in user update request", "USERS")
    status 400
    { error: "Invalid JSON" }.to_json
  rescue PG::Error => e
    AppLogger.log_db_error("UPDATE user", e, { old_email: old_email, new_email: new_email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# DELETE user
# DELETE /user/:email
# Deletes a user by email
# ------------------------------
delete "/user/:email" do
  content_type :json
  email = nil
  begin
    email = Validators.sanitize_email(params[:email])

    unless Validators.valid_email?(email)
      AppLogger.log_validation_error("email", params[:email], "Invalid email format")
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end

    AppLogger.debug("Deleting user: #{email}", "USERS")
    
    # Delete user (combinations will be deleted by CASCADE constraint)
    result = DB.exec_params("DELETE FROM users WHERE email = $1", [email])
    
    if result.cmd_tuples.zero?
      AppLogger.warn("Attempt to delete non-existent user: #{email}", "USERS")
      status 404
      { error: "User not found" }.to_json
    else
      AppLogger.info("User deleted successfully: #{email} (and associated combinations)", "USERS")
      { message: "User deleted", email: email }.to_json
    end

  rescue PG::Error => e
    AppLogger.log_db_error("DELETE user", e, { email: email })
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
