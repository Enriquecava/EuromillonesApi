require 'spec_helper'

RSpec.describe 'DELETE /user/:email' do
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'invalid-email' }

  context 'Given the user email is valid' do
    context 'When the user exists in the database' do
      it 'Then returns the result in JSON format' do
        user_result = double("PG::Result", ntuples: 1, :[] => { "id" => "123" })
        combinations_result = double("PG::Result", :[] => { "count" => "5" })
        delete_result = double("PG::Result", cmd_tuples: 1)

        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)

        allow(DB).to receive(:exec_params)
          .with("SELECT COUNT(*) as count FROM combinations WHERE user_id = $1", ["123"])
          .and_return(combinations_result)

        allow(DB).to receive(:exec_params)
          .with("DELETE FROM users WHERE email = $1", [valid_email])
          .and_return(delete_result)

        delete "/user/#{valid_email}"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json["email"]).to eq(valid_email)
        expect(json["message"]).to eq("User deleted successfully")
        expect(json["combinations_deleted"]).to eq(5)
      end
      it 'Then if there is no combination is should return 0' do
        user_result = double("PG::Result", ntuples: 1, :[] => { "id" => "123" })
        combinations_result = double("PG::Result", :[] => { "count" => "0" })
        delete_result = double("PG::Result", cmd_tuples: 1)

        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)

        allow(DB).to receive(:exec_params)
          .with("SELECT COUNT(*) as count FROM combinations WHERE user_id = $1", ["123"])
          .and_return(combinations_result)

        allow(DB).to receive(:exec_params)
          .with("DELETE FROM users WHERE email = $1", [valid_email])
          .and_return(delete_result)

        delete "/user/#{valid_email}"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json["email"]).to eq(valid_email)
        expect(json["message"]).to eq("User deleted successfully")
        expect(json["combinations_deleted"]).to eq(0)
      end
      it 'Then if the user dissapear during deletion we get an error' do
        user_result = double("PG::Result", ntuples: 1, :[] => { "id" => "123" })
        combinations_result = double("PG::Result", :[] => { "count" => "5" })
        delete_result = double("PG::Result", cmd_tuples: 0)

        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)

        allow(DB).to receive(:exec_params)
          .with("SELECT COUNT(*) as count FROM combinations WHERE user_id = $1", ["123"])
          .and_return(combinations_result)

        allow(DB).to receive(:exec_params)
          .with("DELETE FROM users WHERE email = $1", [valid_email])
          .and_return(delete_result)

        delete "/user/#{valid_email}"

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("User not found")
      end
    end
    context "when a database error occurs" do
      it "returns 500 and a database error message" do
        allow(DB).to receive(:exec_params).and_raise(PG::Error.new("connection lost"))

        delete "/user/#{valid_email}"

        expect(last_response.status).to eq(500)
        json = JSON.parse(last_response.body)

        expect(json["error"]).to eq("Database error")
        expect(json["details"]).to match(/connection lost/)
      end
    end
    context 'When the user does not exist in the database' do
      it 'Then we should get 404 error' do
        user_result = double("PG::Result", ntuples: 0)
        allow(DB).to receive(:exec_params)
          .with("SELECT id FROM users WHERE email = $1", [valid_email])
          .and_return(user_result)
        
        delete "/user/#{valid_email}"

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("User not found")
      end
    end
  end
end
