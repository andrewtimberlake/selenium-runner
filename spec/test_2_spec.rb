describe "Test 2" do
  before(:all) do
    print "pid: #{Process.pid}\n"
  end

  it "should pass" do
    sleep 3
    "b".should_not be_false
  end
end
