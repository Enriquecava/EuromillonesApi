require "playwright"
require_relative "pom/lottery_page"
require "sqlite3"
require "json"

DB = SQLite3::Database.new "euromillones.db"


def save_result(date_str, numbers, stars, prizes)
  DB.execute(
    "INSERT OR REPLACE INTO results (date, bolas, stars, jackpot) VALUES (?, ?, ?, ?)",
    [date_str, numbers.to_json, stars.to_json, prizes.to_json]
  )
  puts "Saved result for #{date_str}"
end

def get_euromillones(date_str)
  url = "https://www.combinacionganadora.com/euromillones/resultados/#{date_str}"

  Playwright.create(playwright_cli_executable_path: `which npx`.strip + " playwright") do |pw|
    browser = pw.chromium.launch(headless: true)
    context = browser.new_context
    page = context.new_page
    page.goto(url)

    lottery_page = LotteryPage.new(page)

    numbers = lottery_page.get_lottery_numbers
    stars   = lottery_page.get_stars_numbers
    prizes  = lottery_page.get_prizes

    browser.close

    save_result(date_str, numbers, stars, prizes)
  end
end

if ARGV.any?
  date_str = ARGV[0]
  get_euromillones(date_str)
else
  puts "Usage: bundle exec ruby scrapper/scrapper.rb yyyy-mm-dd"
end


