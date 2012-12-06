require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Server do
  def app
    Crowdring::Server
  end
  context 'get count of rings' do
    include Rack::Test::Methods

    before(:each) do
      Crowdring::Server.service_handler.reset
      DataMapper.auto_migrate!
      @number1 = '+18001111111'
      @number2 = '+18002222222'
      @number3 = '+18003333333'
      @c = Crowdring::Campaign.create(title: 'test', voice_numbers: [{phone_number: @number2, description: 'num1'}], sms_number: @number3)
      r = Crowdring::Ringer.create(phone_number: @number2)
      @c.voice_numbers.first.ring(r)
    end

    it 'should return unique number of rings for the given campaign' do
      agg = Crowdring::AggregateCampaign.create(name: 'agg', campaigns: [@c])
      get "/campaign/agg/count"
      last_response.ok?
      last_response.body.should == "(#{{:count => 1}.to_json})"
    end
  end
end
