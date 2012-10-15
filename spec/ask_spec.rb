require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ask do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @ringer = Crowdring::Ringer.create(phone_number:@number2)
  end

  describe 'offline ask' do
    it 'should tag a ringer as a supporter on a response' do
      ask = Crowdring::OfflineAsk.create(doubletap: false)
      ask.respond(@ringer)

      ask.respondents(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should trigger the join ask upon receiving a response' do
      ask = Crowdring::OfflineAsk.create(doubletap: true)
      ask.respond(@ringer)

      ask.triggered_ask.recipients(Crowdring::Ringer.all).should eq([@ringer])
    end
  end

end
