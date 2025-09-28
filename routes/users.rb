# users.rb
require "sinatra"
require "json"
require_relative "../db"  

# ------------------------------
# GET user by email
# GET /user/:email
# ------------------------------
get "/user/:email" do
  content_type :json
  begin
    email = params[:email]&.strip

    if email.nil? || email.empty?
      status 400
      return { error: "Email parameter is required" }.to_json
    end

    result = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])

    if result.ntuples.zero?
      status 404
      { error: "User not found" }.to_json
    else
      user = result[0]
      { email: user["email"],
        user_id: user["id"]}.to_json
    end

  rescue PG::Error => e
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
  begin
    payload = JSON.parse(request.body.read)
    email = payload["email"]&.strip

    if email.nil? || email.empty?
      status 400
      return { error: "Email is required" }.to_json
    end
    user = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])
    if user.ntuples > 0
        status 409
        return { error: "Email already exists" }.to_json
    end

    # Insert user; if email exists, do nothing
    DB.exec_params(
      "INSERT INTO users (email) VALUES ($1) ON CONFLICT (email) DO NOTHING",
      [email]
    )

    status 201
    { message: "User created", email: email }.to_json

  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue PG::Error => e
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end

# ------------------------------
# UPDATE user email
# PUT /user/:email
# Body: { "new_email": "new@example.com" }
# ------------------------------
put "/user/:email" do
  content_type :json
  begin
    old_email = params[:email]&.strip
    payload = JSON.parse(request.body.read)
    new_email = payload["email"]&.strip

    if old_email.nil? || old_email.empty? || new_email.nil? || new_email.empty?
      status 400
      return { error: "Both old and new email are required" }.to_json
    end
    new_mail_verification = DB.exec_params("SELECT * FROM users WHERE email = $1", [new_email])
    old_mail_verification = DB.exec_params("SELECT * FROM users WHERE email = $1", [old_email])
    if new_mail_verification.ntuples > 0 
        status 409
        return { error: "New email already exists" }.to_json
    end
    if old_mail_verification.ntuples == 0
        status 404
        return { error: "Old email not found" }.to_json
    end
    result = DB.exec_params(
      "UPDATE users SET email = $1 WHERE email = $2",
      [new_email, old_email]
    )
    { message: "User email updated", old_email: old_email, new_email: new_email }.to_json

  rescue PG::UniqueViolation
    status 409
    { error: "Email already exists" }.to_json
  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue PG::Error => e
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
  begin
    email = params[:email]&.strip

    if email.nil? || email.empty?
      status 400
      return { error: "Email parameter is required" }.to_json
    end

    result = DB.exec_params("DELETE FROM users WHERE email = $1", [email])
    # we should delete user combinations also
    if result.cmd_tuples.zero?
      status 404
      { error: "User not found" }.to_json
    else
      { message: "User deleted", email: email }.to_json
    end

  rescue PG::Error => e
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
