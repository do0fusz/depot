require 'test_helper'

class OrderNotifierTest < ActionMailer::TestCase
  test "received" do
    mail = OrderNotifier.received(orders(:one))
    assert_equal "Order successfully received.", mail.subject
    assert_equal ["my@email.com"], mail.to 
    assert_equal ["www.cyte@gmail.com"], mail.from
  end

  # test "shipped" do
  #   mail = OrderNotifier.shipped(orders(:one))
  #   assert_equal "your order is shipped", mail.subject
  #   assert_equal ["my@email.com"], mail.to
  #   assert_equal ["www.cyte@gmail.com"], mail.from
  # end

end
