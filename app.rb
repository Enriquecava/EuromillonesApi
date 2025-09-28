require "sinatra"
require "sqlite3"
require "json"
require "date"

DB = SQLite3::Database.new "euromillones.db"
DB.results_as_hash = true


# Home endpoint: info about the API
get "/" do
  content_type :json
  {
    api: "Euromillones Results API",
    version: "1.0",
    endpoints: {
      get_result: "/results/:date  (YYYY-MM-DD)",
      add_result: "/results  (POST JSON)",
      health: "/health"
    },
    description: "This API allows you to query Euromillones results by date and insert new results."
  }.to_json
end

# Health check endpoint
get "/health" do
  content_type :json

  begin
    # Simple DB query to check if database is reachable
    DB.execute("SELECT 1")
    status 200
    { status: "OK", message: "API is live and database is reachable" }.to_json
  rescue StandardError => e
    status 500
    { status: "ERROR", message: "API is down or database is unreachable", error: e.message }.to_json
  end
end

# GET result by date (DD/MM/YYYY)
get "/results/:date" do
  date_str = params[:date]

  # Validate format DD/MM/YYYY
  unless date_str =~ /^\d{4}\-\d{2}\-\d{2}$/
    status 400
    return { error: "Invalid date format (use YYYY-MM-DD)" }.to_json
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
  row = DB.get_first_row("SELECT * FROM results WHERE date = ?", [date_str])

  if row
    content_type :json
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


