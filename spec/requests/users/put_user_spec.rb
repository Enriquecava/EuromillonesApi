require 'spec_helper'
RSpec.describe 'PUT /user/:email' do
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'invalid-email' }
  let(:old_email) {'oldemail@mail.com'}

  context 'Given the user email is valid' do
    before(:each) do
      allow(ValidationMiddleware).to receive(:validate_request).and_return({ "email" => valid_email })
    end
    context 'When the user does exist in the database' do
      context 'And the new mail does not exist in the datbase'do
        it 'Then returns the result in JSON format' do
         
          result_mock = double("PG::Result", cmd_tuples: 1)

          allow(DB).to receive(:exec_params).and_return(result_mock)

          put "/user/#{old_email}", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

          expect(last_response.status).to eq(200)
          json = JSON.parse(last_response.body)
          expect(json["new_email"]).to eq(valid_email)
          expect(json["old_email"]).to eq(old_email)
          expect(json["message"]).to eq("User email updated")
        end
      end
      context 'And the new mail exists in the database' do
        it 'Then an error 409 should be returned' do
          allow(DB).to receive(:exec_params).and_raise(PG::UniqueViolation.new("error"))

          put "/user/#{old_email}", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }
          
          expect(last_response.status).to eq(409)
          json = JSON.parse(last_response.body)
          expect(json["error"]).to eq("New email already exists")
        end
      end
    end
    context 'When the user does not exist in the database' do
      it 'Then we should get an error 404' do
        result_mock = double("PG::Result", cmd_tuples: 0)

        allow(DB).to receive(:exec_params).and_return(result_mock)
        put "/user/#{old_email}", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("User not found")
      end
    end
    context 'When the database is down' do
      it 'Then we should have a 500 error' do
        allow(DB).to receive(:exec_params).and_raise(PG::Error.new("connection lost"))

        put "/user/#{old_email}", { email: valid_email }.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(500)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Database error")
      end
    end
  end
end