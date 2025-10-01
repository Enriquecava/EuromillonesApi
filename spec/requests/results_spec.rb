require 'spec_helper'

RSpec.describe "GET /results/:date" do
  let(:valid_date) { "2024-01-02" } # Tuesday
  let(:invalid_date) { "2024-01-01" } # Monday (not a draw day)
  let(:future_date) { (Date.today + 1).strftime("%Y-%m-%d") }
  let(:invalid_format) { "2024/01/02" }

  describe "with valid date" do
    context "when result exists in database" do
      before do
        # Mock database response
        allow(DB).to receive(:exec_params).and_return([{
          "date" => valid_date,
          "bolas" => "[1, 2, 3, 4, 5]",
          "stars" => "[1, 2]",
          "jackpot" => "{\"amount\": 15000000, \"currency\": \"EUR\"}"
        }])
      end

      it "returns the lottery result" do
        get "/results/#{valid_date}"
        
        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include("application/json")
        
        json_response = JSON.parse(last_response.body)
        expect(json_response).to include_json({
          date: valid_date,
          balls: [1, 2, 3, 4, 5],
          stars: [1, 2],
          jackpot: { "amount" => 15000000, "currency" => "EUR" }
        })
      end
    end

    context "when result does not exist in database" do
      before do
        allow(DB).to receive(:exec_params).and_return([])
      end

      it "returns 404 not found" do
        get "/results/#{valid_date}"
        
        expect(last_response.status).to eq(404)
        expect(last_response.content_type).to include("application/json")
        
        json_response = JSON.parse(last_response.body)
        expect(json_response).to include_json({
          error: "No result found for this date"
        })
      end
    end
  end

  describe "with invalid date format" do
    it "returns 400 bad request" do
      get "/results/#{invalid_format}"
      
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to include("application/json")
      
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include_json({
        error: "Invalid date format (use YYYY-MM-DD)",
        field: "date"
      })
    end
  end

  describe "with future date" do
    it "returns 400 bad request" do
      get "/results/#{future_date}"
      
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to include("application/json")
      
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include_json({
        error: "Date cannot be in the future"
      })
    end
  end

  describe "with non-draw day" do
    it "returns 400 bad request for Monday" do
      get "/results/#{invalid_date}"
      
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to include("application/json")
      
      json_response = JSON.parse(last_response.body)
      expect(json_response["error"]).to include("No Euromillones draw on Monday")
    end
  end

  describe "with suspicious patterns" do
    let(:malicious_date) { "2024-01-02'; DROP TABLE results; --" }

    it "returns 400 bad request" do
      get "/results/#{malicious_date}"
      
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to include("application/json")
      
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include_json({
        error: "Invalid date format (use YYYY-MM-DD)",
        field: "date"
      })
    end
  end

  describe "with database error" do
    before do
      allow(DB).to receive(:exec_params).and_raise(PG::Error.new("Connection failed"))
    end

    it "returns 500 internal server error" do
      get "/results/#{valid_date}"
      
      expect(last_response.status).to eq(500)
      expect(last_response.content_type).to include("application/json")
      
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include_json({
        error: "Database error"
      })
    end
  end
end