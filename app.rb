require "sinatra"
require "json"
require "yaml"
require_relative "db"
require_relative "lib/validators"
require_relative "lib/app_logger"
require_relative "lib/auth_middleware"

# Configure CORS for Swagger UI
configure do
  enable :cross_origin
  AppLogger.info("Euromillones API starting up", "STARTUP")
  AppLogger.info("Environment: #{ENV['APP_ENV'] || 'development'}", "STARTUP")
  AppLogger.info("Log level: #{ENV['LOG_LEVEL'] || 'info'}", "STARTUP")
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  
  # Log all requests (except OPTIONS)
  unless request.request_method == 'OPTIONS'
    @request_start_time = Time.now
    AppLogger.debug("Request started: #{request.request_method} #{request.path_info}", "HTTP")
    
    # Apply authentication to API routes (not to docs, swagger, etc.)
    if request.path_info.match?(/^\/(user|combinations|results)/)
      auth_info = AuthMiddleware.authenticate_request(request)
      
      if auth_info.nil?
        content_type :json
        AppLogger.warn("Unauthorized access attempt to: #{request.path_info}", "AUTH")
        halt 401, { error: "Authentication required. Use Basic Auth with nickname:password" }.to_json
      end
      
      # Establecer contexto de autenticación para RLS
      DatabaseConnection.set_user_context(DB, auth_info)
      @current_auth_user = auth_info
      AppLogger.info("Authenticated user #{auth_info[:nickname]} accessing #{request.path_info}", "AUTH")
    end
  end
end

after do
  unless request.request_method == 'OPTIONS'
    duration = @request_start_time ? Time.now - @request_start_time : nil
    AppLogger.log_request(request.request_method, request.path_info, response.status, duration)
  end
end

options "*" do
  response.headers["Allow"] = "GET, POST, PUT, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

# Load separate routes
require_relative "routes/system"
require_relative "routes/users"
require_relative "routes/euromillones"
require_relative "routes/combinations"

# Routes for Swagger UI
get "/swagger.yaml" do
  content_type "application/x-yaml"
  File.read("swagger.yaml")
end

get "/swagger.json" do
  content_type :json
  yaml_content = YAML.load_file("swagger.yaml")
  yaml_content.to_json
end

get "/docs" do
  content_type :html
  swagger_ui_html
end

get "/api-docs" do
  redirect "/docs"
end

def swagger_ui_html
  <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Euromillones API Documentation</title>
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
        <style>
            html {
                box-sizing: border-box;
                overflow: -moz-scrollbars-vertical;
                overflow-y: scroll;
            }
            *, *:before, *:after {
                box-sizing: inherit;
            }
            body {
                margin:0;
                background: #fafafa;
            }
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
        <script>
            window.onload = function() {
                const ui = SwaggerUIBundle({
                    url: '/swagger.json',
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIStandalonePreset
                    ],
                    plugins: [
                        SwaggerUIBundle.plugins.DownloadUrl
                    ],
                    layout: "StandaloneLayout",
                    tryItOutEnabled: true,
                    supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
                    onComplete: function() {
                        console.log("Swagger UI loaded successfully");
                    },
                    onFailure: function(data) {
                        console.log("Failed to load Swagger UI", data);
                    }
                });
            };
        </script>
    </body>
    </html>
  HTML
end

error do
  content_type :json
  status 500
  error_message = env["sinatra.error"].message
  AppLogger.error("Internal server error: #{error_message}", "ERROR")
  AppLogger.error("Backtrace: #{env["sinatra.error"].backtrace.first(5).join(', ')}", "ERROR")
  { error: "Internal server error", details: error_message }.to_json
end

not_found do
  content_type :json
  AppLogger.warn("404 Not Found: #{request.request_method} #{request.path_info}", "HTTP")
  { error: "Not found" }.to_json
end