require "sinatra"
require "json"
require "date"
require_relative "../db"
require_relative "../lib/validators"

# GET result by date (YYYY-MM-DD)
get "/results/:date" do
  date_str = params[:date]&.strip

  # Validate date format
  unless Validators.valid_date_format?(date_str)
    status 400
    return Validators.validation_error("Invalid date format (use YYYY-MM-DD)", "date").to_json
  end

  begin
    # Check if it's a real date
    date = Date.strptime(date_str, "%Y-%m-%d")  # <-- CHANGED
  rescue ArgumentError
    status 400
    return { error: "Invalid date (day or month does not exist)" }.to_json
  end

    # Check if it's in the future
  if date > Date.today
    status 400
    return { error: "Date cannot be in the future" }.to_json
  end

  # Search in database
  row = DB.exec_params("SELECT * FROM results WHERE date = $1", [date_str]).first

  if row
    {
      date: row["date"],
      balls: JSON.parse(row["bolas"]),
      stars: JSON.parse(row["stars"]),
      jackpot: JSON.parse(row["jackpot"])
    }.to_json
  else
    status 404
    { error: "No result found for this date" }.to_json
  end
end
