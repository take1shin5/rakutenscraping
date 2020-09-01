require "selenium-webdriver"

######################## 基本設定 #######################################
options = Selenium::WebDriver::Chrome::Options.new
# options.add_argument('--headless')
driver = Selenium::WebDriver.for :chrome, options: options
driver.manage.window.maximize
driver.manage.timeouts.implicit_wait = 60
wait = Selenium::WebDriver::Wait.new(:timeout => 60)


######################## TOPページから場所検索 #############################
driver.get("https://travel.rakuten.co.jp/")
wait.until{driver.find_element(:xpath, '//*[@id="f_query"]').displayed?}
driver.find_element(:xpath, '//*[@id="f_query"]').send_keys("四万十")
driver.find_element(:xpath, '//*[@id="kw-submit"]').click
wait.until{driver.find_element(:class, 'hotelName').displayed?}


######################## 次のページのボタンがなくなるまで繰り返し ##############
have_next_page = true
hotel_info = []
1.times do 
# while have_next_page do

  #### そのページのホテル軒数判定
  wait.until{driver.find_element(:class, 'hotelName').displayed?}
  num = driver.find_elements(:class, 'hotelName').length

  ### ホテルの軒数分繰り返し
  num.times do |t|
    driver.find_elements(:class, 'hotelName')[t].click

    wait.until{driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').displayed?}

    ### タブメニューのリストの数が2つ以上だった場合、詳細情報のボジ列を含むaタグをクリックする
    clicked = false
    info = false
    if driver.find_element(:id, 'trvlHtlSubNav').find_element(:tag_name, 'ul').find_elements(:tag_name, 'li').length >= 2
      driver.find_element(:id,'trvlHtlSubNav').find_elements(:tag_name, "a").each do |a|
        if a.text.include?("詳細情報")
          driver.find_element(:link_text, "詳細情報").click
          clicked = true
          # wait.until{driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').displayed?}
          sleep 2
        end
      end
      info = true;

    ### タブメニューのリストの数が1つ以下だった場合、クリックせずにホテル情報のスクレイピングを始める
    else 
      if driver.find_element(:id, 'trvlHtlSubNav').find_element(:tag_name, 'ul').find_element(:tag_name, 'li').text.include?("詳細情報")
        info = true;
      end
    end

    if info

      ### ①ホテル名取得
      hotel_info << driver.find_element(:xpath, '//*[@id="RthNameArea"]/h2/a').text

      ### ②住所取得
      hotel_info << driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[0].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      ### ③電話番号取得
      hotel_info << driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[1].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      ### ④交通アクセス取得
      hotel_info << driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[3].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text

      ### ⑤チェックイン・アウト取得
      checkInOut = "チェックイン： #{driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[5].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text}  チェックアウト： #{driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[6].find_element(:tag_name, 'dl').find_element(:tag_name, 'dd').text}"
      hotel_info << checkInOut

      ### ⑥館内設備取得（要素が縦に出力されて見にくい）
      hotel_info << driver.find_element(:class, 'dtlTbl').find_elements(:tag_name, 'li')[8].find_element(:tag_name, 'dl').find_elements(:tag_name, 'dd')[0].find_element(:tag_name, 'ul').text

      ###ホテル情報出力
      puts hotel_info
      puts "###########################################"
    end

    ### 初めから詳細情報ページにいた場合、1ページだけ戻ることでホテルの一覧ページに行ける
    driver.navigate.back
    sleep 2

    ### 詳細ページをクリックした場合のみさらにページバックする
    if clicked
      driver.navigate.back
      sleep 2
    end
      
  end

  #   wait.until{driver.find_element(:class, 'hotelName').displayed?}
  # end
  # if driver.find_element(:class, 'c-pagination__arrow--next')
  #   driver.find_element(:class, 'c-pagination__arrow--next').click
  # else
  #   have_next_page = false
  # end
end
sleep 2
driver.quit