RSpec.describe 'POST /user/' do
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'invalid-email' }

  context 'Given the user email is valid' do
    before(:each) do
      allow(ValidationMiddleware).to receive(:validate_request).and_return({ "email" => valid_email })
    end
    context 'When the user does not exist in the database' do
      it 'Then returns the result in JSON format' do
        fake_row = {
          "id" => "2",
          "email" => valid_email,
          "created_at" => "2023-01-01T00:00:00Z",
          "updated_at" => "2023-01-02T00:00:00Z"
        }
        fake_result = double('PG::Result')
        allow(fake_result).to receive(:ntuples).and_return(1)
        allow(fake_result).to receive(:[]).with(0).and_return(fake_row)

        allow(DB).to receive(:exec_params).and_return(fake_result)

        post "/user", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json["email"]).to eq(valid_email)
      end
    end
    context 'When the user does exist in the database' do
      it 'Then returns a 409 error' do

        fake_result = double('PG::Result')
        allow(fake_result).to receive(:ntuples).and_return(0)
        allow(DB).to receive(:exec_params).and_return(fake_result)

        post "/user", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(409)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Email already exists")
      end
    end

    context "when a database error occurs" do
      it "returns 500 and a database error message" do
        allow(DB).to receive(:exec_params).and_raise(PG::Error.new("connection lost"))

        post "/user", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(500)
        json = JSON.parse(last_response.body)

        expect(json["error"]).to eq("Database error")
        expect(json["details"]).to match(/connection lost/)
      end
    end
  end
  context 'Given the user email is invalid' do
    context 'When the email format is invalid' do
      it 'Then returns 400 with a validation error' do
        allow(ValidationMiddleware).to receive(:validate_request).and_return({ "email" => invalid_email })
        allow(Validators).to receive(:valid_email?).and_return(false)

        post "/user", { email: invalid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Invalid email format")
        expect(json["field"]).to eq("email")
      end
    end

    context 'When the request body is missing the email field' do
      it 'Then returns 400 with a validation error' do
        allow(ValidationMiddleware).to receive(:validate_request).and_return({
          "error" => "Missing required fields",
          "details" => "The following fields are required: email",
          "field" => "required_fields",
          "missing_fields" => ["email"]
        })
        post "/user", {email:''}.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Missing required fields")
        expect(json["field"]).to eq("required_fields")
        expect(json["missing_fields"]).to include("email")
      end
    end
    context 'When the payload size exceeds the limit' do
      it 'Then returns 413 with a validation error' do
        allow(ValidationMiddleware).to receive(:validate_request).and_return({
          "error" => "Payload too large",
          "details" => "The request payload exceeds the maximum allowed size",
          "field" => "payload_size"
        })

        post "/user", { email: 'large@email.com' }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(413)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Payload too large")
        expect(json["field"]).to eq("payload_size")
      end
    end
    context 'When the rate limit is exceeded' do
      it 'Then returns 429 with a validation error' do
        allow(ValidationMiddleware).to receive(:validate_request).and_return({
          "error" => "Rate limit exceeded",
          "details" => "Too many requests from this IP address",
          "field" => "rate_limit"
        })

        post "/user", { email: 'rate_limited@example.com' }.to_json, { "CONTENT_TYPE" => "application/json" }
        expect(last_response.status).to eq(429)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Rate limit exceeded")
        expect(json["field"]).to eq("rate_limit")
      end
    end
    context 'When the request body is not valid JSON' do
      it 'Then returns 400 with a validation error' do
        allow(ValidationMiddleware).to receive(:validate_request).and_return({
          "error" => "Invalid JSON format",
          "details" => "unexpected token at 'invalid-json'",
          "field" => "json_parse"
        })

        post "/user", "invalid-json", { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Invalid JSON format")
        expect(json["field"]).to eq("json_parse")
      end
    end
  end
end