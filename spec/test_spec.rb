visit "http://www.google.com", "A Google search for Clay" do
  before(:all) do
    element = driver.find_element(:name, 'q')
    element.send_keys 'Clay'
    element.submit
    wait = Selenium::WebDriver::Wait.new(:timeout => 10)
    wait.until { driver.find_element(:id => 'rso') }
  end

  it "should have 'Clay' in the title" do
    driver.title.should match(/clay/)
  end
end
