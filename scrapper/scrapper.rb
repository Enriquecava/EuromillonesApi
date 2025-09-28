require "playwright"
require_relative "pom/lottery_page"
require "pg"
require "json"
require "dotenv/load"

DB = PG.connect(
  host: ENV['PG_HOST'],
  port: ENV['PG_PORT'],
  dbname: ENV['PG_DB'],
  user: ENV['PG_USER'],
  password: ENV['PG_PASSWORD'],
  sslmode: 'require'
)


def save_result(date_str, numbers, stars, prizes)
 DB.exec_params(
  "INSERT INTO results (date, bolas, stars, jackpot)
   VALUES ($1, $2, $3, $4)
   ON CONFLICT (date) DO UPDATE
   SET bolas = EXCLUDED.bolas,
       stars = EXCLUDED.stars,
       jackpot = EXCLUDED.jackpot",
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


