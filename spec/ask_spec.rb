require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ask do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @number3 = '+18004444444'
    @ringer = Crowdring::Ringer.create(phone_number:@number2)
    @ringer2 = Crowdring::Ringer.create(phone_number:@number4)
    @response_numbers = Crowdring::ResponseNumbers.new(voice_number: @number1, sms_number: @number3)
  end

  describe 'offline ask' do
    it 'should tag a ringer as a supporter on a response' do
      ask = Crowdring::OfflineAsk.create
      ask.respond(@ringer, @response_numbers)

      ask.respondents(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should trigger the join ask upon receiving a response' do
      ask = Crowdring::Ask.create_double_opt_in(nil)
      ask.respond(@ringer, @response_numbers)

      ask.triggered_ask.recipients(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should handle any incoming ring' do
      ask = Crowdring::OfflineAsk.create
      ask.handle?(@ringer).should be_true
    end
  end

  describe 'join ask' do
    it 'should send a message to a ringer upon being triggered' do
      message = double('message', id: 1)
      message.should_receive(:send_message).once.with(from: @number3, to: @ringer)

      ask = Crowdring::JoinAsk.new(message: message)
      ask.trigger_for(@ringer, @response_numbers)
    end

    it 'should handle an incoming ring that it has sent a join ask to' do
      ask = Crowdring::JoinAsk.create
      ask.handle?(@ringer).should be_false
      ask.trigger_for(@ringer, @response_numbers)
      ask.handle?(@ringer).should be_true
    end
  end

end
