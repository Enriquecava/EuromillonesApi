require "sinatra"
require "json"
require_relative "../db"
require_relative "../lib/validators"


# Home endpoint: info about the API
get "/" do
  content_type :json
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
      get_combinations: "/combinations/:user_id (GET)",
      update_combination: "/combinations/:id (PUT)",
      delete_combination: "/combinations/:id (DELETE)",
      health: "/health"
    },
    description: "This API allows you to query Euromillones results, manage users and their combinations."
  }.to_json
end

# Health check endpoint
get "/health" do
  content_type :json

  begin
    # Simple DB query to check if database is reachable
    DB.exec_params("SELECT 1")
    status 200
    { status: "OK", message: "API is live and database is reachable" }.to_json
  rescue StandardError => e
    status 500
    { status: "ERROR", message: "API is down or database is unreachable", error: e.message }.to_json
  end
end

