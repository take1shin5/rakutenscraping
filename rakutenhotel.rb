require "csv"
require "selenium-webdriver"

######################## 基本設定 #######################################
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
@driver = Selenium::WebDriver.for :chrome, options: options
@driver.manage.window.resize_to(10000,10000)
@driver.manage.timeouts.implicit_wait = 60
wait = Selenium::WebDriver::Wait.new(:timeout => 60)

### 要素があるかないかの判定メソッド
def element_present?(how, what)
  @driver.manage.timeouts.implicit_wait = 0
  @driver.find_element(how, what)
  true
rescue Selenium::WebDriver::Error::NoSuchElementError
  false
end

######################### csv準備
CSV.open("/Users/shingotakei/Desktop/abc.csv", "w") do |c|
  c << ["ホテル名 name characterVarying", "住所 address characterVaring", "電話番号 tel CharacterVaring", "交通アクセス location_text characterVaring", "チェックイン・アウト時間 holiday_text characterVaring", "館内設備 zip characterVarying", "支払い方法 price_text characterVarying"]
end

######################## TOPページから場所検索 #############################
@driver.get("https://travel.rakuten.co.jp/")
wait.until{@driver.find_element(:xpath, '//*[@id="f_query"]').displayed?}
@driver.find_element(:xpath, '//*[@id="f_query"]').send_keys("四万十")
@driver.find_element(:xpath, '//*[@id="kw-submit"]').click
wait.until{@driver.find_element(:class, 'hotelName').displayed?}


######################## 次のページのボタンがなくなるまで繰り返し ##############
have_next_page = true

# num = 1
# page = 1
while have_next_page do 

  #### そのページのホテル軒数判定
  wait.until{@driver.find_element(:class, 'hotelName').displayed?}
  num = @driver.find_elements(:class, 'hotelName').length

  ### ホテルの軒数分繰り返し
  num.times do |t|
    hotel_info = []
    @driver.find_elements(:class, 'hotelName')[t].click

    wait.until{@driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').displayed?}

    ### タブメニューのリストの数が2つ以上だった場合、詳細情報のボジ列を含むaタグをクリックする
    clicked = false
    info = false
    if @driver.find_element(:id, 'trvlHtlSubNav').find_element(:tag_name, 'ul').find_elements(:tag_name, 'li').length >= 2
      @driver.find_element(:id,'trvlHtlSubNav').find_elements(:tag_name, "a").each do |a|
        if a.text.include?("詳細情報")
          @driver.find_element(:link_text, "詳細情報").click
          clicked = true
          # wait.until{@driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').displayed?}
          sleep 2
        end
      end
      info = true;

    ### タブメニューのリストの数が1つ以下だった場合、クリックせずにホテル情報のスクレイピングを始める
    else 
      if @driver.find_element(:id, 'trvlHtlSubNav').find_element(:tag_name, 'ul').find_element(:tag_name, 'li').text.include?("詳細情報")
        info = true;
      end
    end

    if info

      ### ①ホテル名取得
      hotel_info << @driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').text

      # ### ②住所取得
      hotel_info << @driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[0].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      # ### ③電話番号取得
      hotel_info << @driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[1].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      # ### ④交通アクセス取得
      hotel_info << @driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[3].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      # ### ⑤チェックイン・アウト取得
      checkInOut = "チェックイン： #{@driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[5].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text}  チェックアウト： #{@driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[6].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text}"
      hotel_info << checkInOut

      # ### ⑥館内設備取得（要素が縦に出力されて見にくい）
      genre = "#{@driver.find_elements(:class, "eqHght")[0].text}"
      hotel_info << genre.gsub(/\n/, "  ")
      # hotel_info << @driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[8].find_element(:tag_name, 'dl').find_elements(:tag_name, 'dd')[0].find_element(:tag_name, 'ul').text

      # ### ⑦カード（支払い方法）取得
      card = "#{@driver.find_elements(:class, "eqHght")[-1].text}"
      hotel_info << card.gsub(/\n/, "  ")
      # # datas << @driver.find_elements(:class, "eqHght")[-1].find_elements(:tag_name, 'li')
      # # datas << @driver.find_elements(:class, 'dtlTbl')[-1].find_elements(:tag_name, 'li').find_elements(:tag_name, 'dl').find_elements(:tag_name, 'dd').find_elements(:tag_name, 'ul').find_elements(:tag_name, 'li')
      # # datas = []
      # # datas << @driver.find_elements(:class, "eqHght")[-1].text
      # # datas.each do |data|
      # #   puts data
      # # end

      CSV.open("/Users/shingotakei/Desktop/abc.csv", "a") do |c|
        c << hotel_info
      end

      ###ホテル情報出力
      puts hotel_info
      puts "###########################################"
    end

    ### 初めから詳細情報ページにいた場合、1ページだけ戻ることでホテルの一覧ページに行ける
    @driver.navigate.back
    sleep 2

    ### 詳細ページをクリックした場合のみさらにページバックする
    if clicked
      @driver.navigate.back
      sleep 2
    end
      
  end
  ### そのページのホテルが全部終わったら次のページがあるかで分岐する
  
  if element_present?(:class, 'pagingBack')
    @driver.find_element(:class, 'pagingBack').click
  else
    have_next_page = false
  end
  
end
sleep 2
@driver.quit