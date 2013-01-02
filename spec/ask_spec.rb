require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ask do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @number4 = '+18004444444'
    @ringer = Crowdring::Ringer.create(phone_number:@number2)
    @ringer2 = Crowdring::Ringer.create(phone_number:@number4)
    @sms_number = @number3 

    @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
    @fooservice = double('fooservice', build_response: 'fooResponse',
        sms?: true,
        transform_request: @fooresponse,
        numbers: [@number3],
        send_sms: nil)
    Crowdring::CompositeService.instance.reset
    Crowdring::CompositeService.instance.add('foo', @fooservice) 
  end

  describe 'offline ask' do
    it 'should tag a ringer as a supporter on a response' do
      ask = Crowdring::OfflineAsk.create(title: 'offline ask')
      ask.respond(@ringer, @sms_number)

      ask.respondents(Crowdring::Ringer.all).should eq([@ringer])
    end

    it 'should handle any incoming ring' do
      ask = Crowdring::OfflineAsk.create(title: 'offline ask')
      ask.handle?(:voice, @ringer).should be_true
    end
  end

  describe 'join ask' do
    it 'should send a message to a ringer upon being triggered' do
      message = double('message', id: 1)
      message.should_receive(:send_message).once.with(from: @number3, to: @ringer)

      ask = Crowdring::JoinAsk.new(message: message)
      ask.trigger_for(@ringer, @sms_number)
    end

    it 'should handle an incoming ring that it has sent a join ask to' do
      ask = Crowdring::JoinAsk.create
      ask.handle?(:voice, @ringer).should be_false
      ask.trigger_for(@ringer, @sms_number)
      ask.handle?(:voice, @ringer).should be_true
    end
  end

  describe 'text ask' do
    it 'should record response from ringer' do
      message = Crowdring::Message.new(default_message: 'blah')
      text = Crowdring::Text.new(message: 'BLAH', ringer: @ringer)
      ask = Crowdring::TextAsk.new(title: 'text ask', message: message)

      ask.trigger_for(@ringer, @sms_number)
      ask.text(@ringer, text, @sms_number)

      ask.texts.count.should eq(1)
      ask.texts.first.should eq(text)
    end

    it 'should extract email from text message' do
      message = Crowdring::Message.new(default_message: 'blah')
      text = Crowdring::Text.new(message: 'BLAH@gmail.com, thanks', ringer: @ringer)
      ask = Crowdring::TextAsk.new(title: 'text ask', message: message)

      ask.trigger_for(@ringer, @sms_number)
      ask.text(@ringer, text, @sms_number)
      @ringer.email.should eq('BLAH@gmail.com')
    end

  end
end
