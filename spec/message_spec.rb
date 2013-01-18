require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Message do

  before(:each) do
    DataMapper::auto_migrate!
 
    @number = '+18001111111'
    @number2 = '+18002222222'
     
  end

  it 'should allow creation of an empty default message when other messages are provided' do
    intro_response = Crowdring::Message.new(
      default_message: '',
      filtered_messages: [{constraints: ['area code:814'], message_text: 'to 814'}])
    intro_response.save.should be_true
    ir = Crowdring::Message.first
    ir.should_not be_nil
    ir.default_message.should be_nil
    ir.filtered_messages.count.should eq(1)
  end
  describe "should be able to filter ringer and send message" do
    
    before(:each) do 
      @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
      @fooservice = double('fooservice', build_response: 'fooResponse',
        sms?: true,
        transform_request: @fooresponse,
        numbers: [@number],
        send_sms: nil)
    @ringer = double('ringer', phone_number: @number2, subscribed?: true)
    Crowdring::CompositeService.instance.reset
    Crowdring::CompositeService.instance.add('foo', @fooservice)
  end

    it 'should send the first matched message to a ringer'  do
      pittsburgh = Crowdring::Tag.from_str('area code:412')
      chicago = Crowdring::Tag.from_str('area code:312')
      fm = Crowdring::FilteredMessage.new(constraints: [Crowdring::HasConstraint.create(tag: pittsburgh)], message_text: 'pittsburgh')
      fm2 = Crowdring::FilteredMessage.new(constraints: [Crowdring::HasNotConstraint.create(tag: chicago)], message_text: 'chicago')

      intro_response = Crowdring::Message.create(filtered_messages: [fm, fm2])
      
      @ringer.stub(:tags) { [pittsburgh] }
      @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'pittsburgh')

      intro_response.send_message(from: @number, to: @ringer)
    end
  end
end