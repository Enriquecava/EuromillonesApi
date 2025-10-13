require 'spec_helper'

RSpec.describe 'GET /user/:email' do
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'invalid-email' }

  context 'Given the user email is valid' do
    context 'When the user exists in the database' do
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

        get "/user/#{valid_email}"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json["user_id"]).to eq("2")
        expect(json["email"]).to eq(valid_email)
      end
    end

    context 'When the user does not exist in the database' do
      it 'Then returns 404 with an error message' do
        fake_result = double('PG::Result')
        allow(fake_result).to receive(:ntuples).and_return(0)

        allow(DB).to receive(:exec_params).and_return(fake_result)

        get "/user/#{valid_email}"

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("User not found")
      end
    end
  end

  context 'Given the user email is invalid' do
    context 'When the email format is invalid' do
      it 'Then returns 400 with a validation error' do
        allow(Validators).to receive(:valid_email?).and_return(false)

        get "/user/#{invalid_email}"

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Invalid email format")
        expect(json["field"]).to eq("email")
      end
    end

    context 'When the email contains suspicious patterns' do
      it 'Then returns 400 with a validation error' do
        allow(Validators).to receive(:contains_suspicious_patterns?).and_return(true)

        get "/user/#{invalid_email}"

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Invalid email format")
        expect(json["field"]).to eq("email")
      end
    end
  end

  context "when a database error occurs" do
    it "returns 500 and a database error message" do
      allow(DB).to receive(:exec_params).and_raise(PG::Error.new("connection lost"))

      get "/user/test@example.com"

      expect(last_response.status).to eq(500)
      json = JSON.parse(last_response.body)

      expect(json["error"]).to eq("Database error")
      expect(json["details"]).to match(/connection lost/)
    end
  end
end
