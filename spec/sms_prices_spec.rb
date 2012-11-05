require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::SMSPrices do
  it 'should calculate the cost of sending a single outgoing sms' do
    to = Phoner::Phone.parse '+18002222222'
    prices = {'tester' => {'US' => 5}}

    Crowdring::SMSPrices.price_for('tester', to, prices: prices).should eq(5)
  end 
end

