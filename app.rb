require "sinatra"
require "json"
require_relative "db"

# Cargar rutas separadas
require_relative "routes/system"
require_relative "routes/users"
require_relative "routes/euromillones"
require_relative "routes/combinations"

error do
  content_type :json
  status 500
  { error: "Internal server error", details: env["sinatra.error"].message }.to_json
end

not_found do
  content_type :json
  { error: "Not found" }.to_json
end