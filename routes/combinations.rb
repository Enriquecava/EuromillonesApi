# combinations.rb
require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"

# ------------------------------
# CREATE a new combination for a user
# POST /combinations
# Body: { "email": "user@example.com", "balls": [1,2,3,4,5], "stars": [1,2] }
# ------------------------------
post "/combinations" do
  content_type :json
  begin
    payload = JSON.parse(request.body.read)
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
    # Check if user exists
    user = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])
    if user.ntuples == 0
        status 404
        return { error: "User not found" }.to_json
    end

    existing = DB.exec_params(
        "SELECT id FROM combinations WHERE user_id = $1 AND balls = $2 AND stars = $3",
        [user[0]["id"], balls.to_json, stars.to_json]
    )
    if existing.ntuples > 0
        status 409
        return { error: "Combination already exists for this user" }.to_json
    end
     # Insert new combination
    result = DB.exec_params(
        "INSERT INTO combinations (user_id, balls, stars) VALUES ($1, $2, $3) RETURNING id",
        [user[0]["id"], balls.to_json, stars.to_json]
    )
    combination_id = result[0]["id"]
    status 201
    { message: "Combination successfully added", email: email, balls: balls, stars: stars, combination_id: combination_id }.to_json

  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue PG::Error => e
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
  begin
    email = Validators.sanitize_email(params[:email])

    unless Validators.valid_email?(email)
      status 400
      return Validators.validation_error("Invalid email format", "email").to_json
    end
    user = DB.exec_params("SELECT * FROM users WHERE email = $1", [email])
    if user.ntuples == 0
        status 404
        return { error: "User not found" }.to_json
    end
    if user.ntuples >1
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

    { email: email, combinations: combinations }.to_json

  rescue PG::Error => e
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
  begin
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

    user = DB.exec_params(
        "SELECT user_id FROM combinations WHERE id = $1",
        [id]
    )
    if user.ntuples > 0
        user_id = user[0]["user_id"]
    else
        status 404
        return { error: "Combination not found" }.to_json
    end

    existing = DB.exec_params(
        "SELECT id FROM combinations WHERE user_id = $1 AND balls = $2 AND stars = $3",
        [user_id, balls.to_json, stars.to_json]
    )
    if existing.ntuples > 0
        status 409
        return { error: "Combination already exists for this user" }.to_json
    end

    result = DB.exec_params(
      "UPDATE combinations SET balls = $1, stars = $2 WHERE id = $3",
      [balls.to_json, stars.to_json, id]
    )

    if result.cmd_tuples.zero?
      status 404
      { error: "Combination not found" }.to_json
    else
      { message: "Combination updated", id: id, balls: balls, stars: stars }.to_json
    end

  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue PG::Error => e
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
  begin
    unless Validators.valid_combination_id?(params[:id])
      status 400
      return Validators.validation_error("Invalid combination ID", "id").to_json
    end

    id = params[:id].to_i

    result = DB.exec_params("DELETE FROM combinations WHERE id = $1", [id])

    if result.cmd_tuples.zero?
      status 404
      { error: "Combination not found" }.to_json
    else
      { message: "Combination deleted", id: id }.to_json
    end

  rescue PG::Error => e
    status 500
    { error: "Database error", details: e.message }.to_json
  end
end
