require "json"
require "pg"
require "dotenv/load"
require_relative "db"

def count_matches(user_numbers, winning_numbers)
  user_array = JSON.parse(user_numbers)
  winning_array = JSON.parse(winning_numbers)
  
  user_normalized = user_array.map { |n| n.to_i }
  winning_normalized = winning_array.map { |n| n.to_i }
  
  (user_normalized & winning_normalized).length
rescue
  0
end

def get_prize(jackpot_json, balls_matched, stars_matched)
  jackpot = JSON.parse(jackpot_json)
  balls_key = balls_matched.to_s
  stars_key = stars_matched.to_s
  
  if jackpot[balls_key] && jackpot[balls_key][stars_key]
    jackpot[balls_key][stars_key].to_f
  else
    0.0
  end
rescue
  0.0
end

def check_winners(date)
  result_query = "SELECT bolas, stars, jackpot FROM results WHERE date = $1"
  lottery_result = DB.exec_params(result_query, [date])
  
  if lottery_result.ntuples == 0
    return { error: "No lottery result found for #{date}" }
  end
  
  result_row = lottery_result[0]
  winning_balls = result_row['bolas']
  winning_stars = result_row['stars']
  jackpot = result_row['jackpot']

  combinations_query = "SELECT u.email, c.balls, c.stars FROM users u JOIN combinations c ON u.id = c.user_id"
  combinations = DB.exec_params(combinations_query, [])
  winners = []
  
  combinations.each do |row|
    email = row['email']
    user_balls = row['balls']
    user_stars = row['stars']
    
    balls_matched = count_matches(user_balls, winning_balls)
    stars_matched = count_matches(user_stars, winning_stars)
    
    prize = get_prize(jackpot, balls_matched, stars_matched)
    
    if prize > 0
      winners << {
        email: email,
        prize: sprintf("%.2f €", prize)
      }
    end
  end
  
  {
    date: date,
    winning_combination: {
      balls: JSON.parse(winning_balls),
      stars: JSON.parse(winning_stars),
      jackpot: JSON.parse(jackpot),
    },
    winners: winners,
    total_winners: winners.length
  }
rescue => e
  { error: "Database error: #{e.message}" }
end

def valid_date?(date_str)
  date_str&.match?(/^\d{4}-\d{2}-\d{2}$/)
end

if __FILE__ == $0
  if ARGV.empty?
    puts JSON.pretty_generate({ error: "Date required. Usage: ruby prize_winners.rb YYYY-MM-DD" })
    exit 1
  end
  
  date = ARGV[0].strip

  unless valid_date?(date)
    puts JSON.pretty_generate({ error: "Invalid date format. Use YYYY-MM-DD" })
    exit 1
  end

  result = check_winners(date)
  puts JSON.pretty_generate(result)

  if result[:error]
    exit 1
  elsif result[:winners].any?
    exit 0
  else
    exit 0
  end
end