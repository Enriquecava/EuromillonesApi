require "sinatra"
require "json"
require "yaml"
require_relative "db"
require_relative "lib/validators"

# Configurar CORS para Swagger UI
configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
end

options "*" do
  response.headers["Allow"] = "GET, POST, PUT, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

# Cargar rutas separadas
require_relative "routes/system"
require_relative "routes/users"
require_relative "routes/euromillones"
require_relative "routes/combinations"

# Rutas para Swagger UI
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
  { error: "Internal server error", details: env["sinatra.error"].message }.to_json
end

not_found do
  content_type :json
  { error: "Not found" }.to_json
end