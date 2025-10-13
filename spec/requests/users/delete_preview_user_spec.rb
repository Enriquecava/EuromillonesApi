require 'spec_helper'

RSpec.describe 'GET /user/:email' do
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'invalid-email' }

  context 'Given the user email is valid' do
    context 'When the user exists in the database' do
      it 'Then returns the result in JSON format' do

        user_result = double("PG::Result", ntuples: 1, :[] => { "id" => "123" })
        combinations_result = double("PG::Result", :[] => { "count" => "5" })
        
        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)

        allow(DB).to receive(:exec_params)
          .with("SELECT COUNT(*) as count FROM combinations WHERE user_id = $1", ["123"])
          .and_return(combinations_result)



        get "/user/#{valid_email}/delete-preview"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json["user_id"]).to eq(123)
        expect(json["email"]).to eq(valid_email)
        expect(json["combinations_to_delete"]).to eq(5)
        expect(json["warning"]).to eq("Deleting this user will permanently remove all associated combinations")
      end
    end

    context 'When the user does not exist in the database' do
      it 'Then returns 404 with an error message' do
        user_result = double("PG::Result", ntuples: 0)
        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)

        get "/user/#{valid_email}/delete-preview"

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("User not found")
      end
    end
    context "when a database error occurs" do
      it "returns 500 and a database error message" do
        allow(DB).to receive(:exec_params).and_raise(PG::Error.new("connection lost"))

        get "/user/#{valid_email}/delete-preview"

        expect(last_response.status).to eq(500)
        json = JSON.parse(last_response.body)

        expect(json["error"]).to eq("Database error")
        expect(json["details"]).to match(/connection lost/)
      end
    end
  end
end
