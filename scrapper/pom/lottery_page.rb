class LotteryPage
  def initialize(page)
    @page = page
    @number_one   = page.locator('ul[aria-label="Números"] >> li').nth(0)
    @number_two   = page.locator('ul[aria-label="Números"] >> li').nth(1)
    @number_three = page.locator('ul[aria-label="Números"] >> li').nth(2)
    @number_four  = page.locator('ul[aria-label="Números"] >> li').nth(3)
    @number_five  = page.locator('ul[aria-label="Números"] >> li').nth(4)

    @star_one = page.locator('[title="Estrellas"]').nth(0).locator('..')
    @star_two = page.locator('[title="Estrellas"]').nth(1).locator('..')

    @prize_category = page.locator('[data-cat=""]')
    @prize_money    = page.locator('[data-prize=""]')
  end

  def get_nth_prize_category(value)
    category = @prize_category.nth(value).text_content
    string = category.split("(")[1].split(")")[0]
    numbers = string.chars.select { |c| c =~ /\d/ }.map(&:to_i)
    balls, stars = numbers
    [balls, stars]
  end

  def get_nth_prize_money(value)
    money = @prize_money.nth(value).text_content
    money.gsub(" €", "").gsub(".", "").gsub(",", ".")
  end

  def get_prizes
    data = {}
    (1..12).each do |i|
      category = get_nth_prize_category(i)
      money = get_nth_prize_money(i)

      balls_key = category[0].to_s
      stars_key = category[1].to_s

      data[balls_key] ||= {}
      data[balls_key][stars_key] = money
    end
    data
  end

  def get_first_number
    @number_one.text_content
  end

  def get_second_number
    @number_two.text_content
  end

  def get_third_number
    @number_three.text_content
  end

  def get_fourth_number
    @number_four.text_content
  end

  def get_fifth_number
    @number_five.text_content
  end

  def get_first_star
    content = @star_one.text_content
    content.gsub("E", "").strip
  end

  def get_second_star
    content = @star_two.text_content
    content.gsub("E", "").strip
  end

  def get_lottery_numbers
    [
      get_first_number,
      get_second_number,
      get_third_number,
      get_fourth_number,
      get_fifth_number
    ]
  end

  def get_stars_numbers
    [
      get_first_star,
      get_second_star
    ]
  end
end
