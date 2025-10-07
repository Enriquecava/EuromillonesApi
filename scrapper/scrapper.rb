require "playwright"
require_relative "pom/lottery_page"
require_relative "../lib/app_logger"
require "pg"
require "json"
require "dotenv/load"
require_relative "../db"


def save_result(date_str, numbers, stars, prizes)
  AppLogger.debug("Saving lottery result for date: #{date_str}", "SCRAPER")
  begin
    DB.exec_params(
      "INSERT INTO results (date, bolas, stars, jackpot) " +
      "VALUES ($1, $2, $3, $4) " +
      "ON CONFLICT (date) DO UPDATE " +
      "SET bolas = EXCLUDED.bolas, " +
      "    stars = EXCLUDED.stars, " +
      "    jackpot = EXCLUDED.jackpot",
      [date_str, numbers.to_json, stars.to_json, prizes.to_json]
    )
    AppLogger.info("Successfully saved lottery result for #{date_str}", "SCRAPER")
  rescue PG::Error => e
    AppLogger.log_db_error("INSERT/UPDATE result", e, { date: date_str, numbers: numbers, stars: stars })
    raise e
  end
end

def get_euromillones(date_str)
  url = "https://www.combinacionganadora.com/euromillones/resultados/#{date_str}"
  
  AppLogger.info("Starting scraper for date: #{date_str}", "SCRAPER")
  AppLogger.debug("Target URL: #{url}", "SCRAPER")

  begin
    Playwright.create(playwright_cli_executable_path: `which npx`.strip + " playwright") do |pw|
      AppLogger.debug("Launching browser", "SCRAPER")
      browser = pw.chromium.launch(headless: true)
      context = browser.new_context
      page = context.new_page
      
      AppLogger.debug("Navigating to lottery page", "SCRAPER")
      page.goto(url)

      lottery_page = LotteryPage.new(page)

      AppLogger.debug("Extracting lottery data", "SCRAPER")
      numbers = lottery_page.get_lottery_numbers
      stars   = lottery_page.get_stars_numbers
      prizes  = lottery_page.get_prizes

      AppLogger.debug("Extracted data - Numbers: #{numbers}, Stars: #{stars}", "SCRAPER")
      browser.close

      save_result(date_str, numbers, stars, prizes)
      AppLogger.info("Scraper completed successfully for date: #{date_str}", "SCRAPER")
    end
  rescue StandardError => e
    AppLogger.error("Scraper failed for date #{date_str}: #{e.message}", "SCRAPER")
    AppLogger.error("Backtrace: #{e.backtrace.first(3).join(', ')}", "SCRAPER")
    raise e
  end
end

if ARGV.any?
  date_str = ARGV[0]
  AppLogger.info("Scraper started with date argument: #{date_str}", "SCRAPER")

  unless date_str.match?(/^\d{4}-\d{2}-\d{2}$/)
    AppLogger.error("Invalid date format provided: #{date_str}. Expected YYYY-MM-DD", "SCRAPER")
    puts "Error: Invalid date format. Use YYYY-MM-DD"
    exit 1
  end
  
  begin
    get_euromillones(date_str)
  rescue StandardError => e
    AppLogger.fatal("Scraper execution failed: #{e.message}", "SCRAPER")
    puts "Error: #{e.message}"
    exit 1
  end
else
  AppLogger.warn("Scraper started without date argument", "SCRAPER")
  puts "Usage: bundle exec ruby scrapper/scrapper.rb yyyy-mm-dd"
  exit 1
end


