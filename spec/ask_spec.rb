require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ask do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @ringer = Crowdring::Ringer.create(phone_number:@number2)
    @ring = Crowdring::Ring.create(ringer: @ringer, number_rang: Crowdring::AssignedPhoneNumber.create(phone_number: @number1)) 
  end

  describe 'offline ask' do
    it 'should tag a ringer as a supporter on a response' do
      ask = Crowdring::OfflineAsk.create
      ask.respond(@ring)

      ask.respondents(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should trigger the join ask upon receiving a response' do
      ask = Crowdring::Ask.create_double_opt_in(nil)
      ask.respond(@ring)

      ask.triggered_ask.recipients(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should handle any incoming ring' do
      ask = Crowdring::OfflineAsk.create
      ask.handle?(@ring).should be_true
    end
  end

  describe 'join ask' do
    it 'should send a message to a ringer upon being triggered' do
      message = double('message', id: 1)
      message.should_receive(:send_message).once.with(from: @ring.number_rang.phone_number, to: @ringer)

      ask = Crowdring::JoinAsk.new(message: message)
      ask.trigger_for(@ring)
    end

    it 'should handle an incoming ring that it has sent a join ask to' do
      ask = Crowdring::JoinAsk.create
      ask.handle?(@ring).should be_false
      ask.trigger_for(@ring)
      ask.handle?(@ring).should be_true
    end

  end

end
