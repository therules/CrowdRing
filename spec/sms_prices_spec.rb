require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::SMSPrices do
  it 'should calculate the cost of sending an sms' do
    to = Phoner::Phone.parse '+18002222222'
    prices = {'tester' => {'US' => 5}}

    Crowdring::SMSPrices.price_for('tester', to, prices: prices).should eq(5)
  end

  it 'should return nil if it does not know the service to be used for sending' do
    to = Phoner::Phone.parse '+18002222222'
    prices = {'tester' => {'US' => 5}}

    Crowdring::SMSPrices.price_for('unknown', to, prices: prices).should be_nil
  end

  it 'should return nil if it knows the service but not the country being sent to' do
    to = Phoner::Phone.parse '+918002222222'
    prices = {'tester' => {'US' => 5}}

    Crowdring::SMSPrices.price_for('tester', to, prices: prices).should be_nil
  end

end

