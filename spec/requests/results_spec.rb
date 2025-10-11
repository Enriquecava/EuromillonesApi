# spec/results_spec.rb
require 'spec_helper'

RSpec.describe 'GET /results/:date' do
  previous_wednesday = (Date.today - ((2 - Date.today.wday) % 7)).strftime("%Y-%m-%d")
  future_date = (Date.today + 3).strftime("%Y-%m-%d")

  context 'when the lottery result exists in the database' do
    it 'returns the result in JSON format' do
      allow(Validators).to receive(:valid_euromillones_draw_day?).and_return(true)
      fake_row = {
        "date" => "2024-12-20",
        "bolas" => "[1,2,3,4,5]",
        "stars" => "[6,7]",
        "jackpot" => '{"amount":1000000}'
      }
      allow(DB).to receive(:exec_params).and_return([fake_row])
      get '/results/2024-12-20'
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json["date"]).to eq("2024-12-20")
      expect(json["balls"]).to eq([1,2,3,4,5])
      expect(json["stars"]).to eq([6,7])
      expect(json["jackpot"]["amount"]).to eq(1_000_000)
    end
  end

  context 'when no result exists for the date' do
    it 'returns 404 with an error message' do
      allow(Validators).to receive(:valid_euromillones_draw_day?).and_return(true)
      allow(DB).to receive(:exec_params).and_return([])
      get '/results/2024-12-20'
      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("No result found for this date")
    end
  end

  context 'when the date format is invalid' do
    it 'returns 400 with a validation error' do
      allow(Validators).to receive(:valid_date_format?).and_return(false)

      get '/results/2024-13-50'

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to match(/Invalid date format/)
    end
  end

  context 'when the date is in the future' do
    it 'returns 400 with a proper error message' do
      get "/results/#{future_date}"
      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Date cannot be in the future")
    end
  end
  context 'when the date is not a tuesday/friday' do
    it 'returns 400 with a proper error message' do
      get "/results/#{previous_wednesday}"
      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("No Euromillones draw on Wednesday. Draws are held on Tuesdays and Fridays only.")
    end
  end
end
