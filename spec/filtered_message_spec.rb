require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::FilteredMessage do
  before(:each) do
    DataMapper.auto_migrate!

    @number = '+18001111111'
    @number2 = '+18002222222'
    @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
    @fooservice = double('fooservice', build_response: 'fooResponse',
        sms?: true,
        transform_request: @fooresponse,
        numbers: [@number],
        send_sms: nil)
    Crowdring::CompositeService.instance.reset
    Crowdring::CompositeService.instance.add('foo', @fooservice)
  end

  it 'should send a message to an accepted recipient' do
    tag_filter = Crowdring::TagFilter.create(constraints: ['area code:412'])
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message_text: 'msg')

    ringer = double('ringer', tags: [pittsburgh], phone_number: @number2, subscribed?: true)

    @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'msg')
    fm.send_message(from: @number, to:ringer)
  end

  it 'should return true if it sent a message to the recipient' do
    tag_filter = Crowdring::TagFilter.create(constraints: ['area code:412'])
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message_text: 'msg')

    ringer = double('ringer', tags: [pittsburgh], phone_number: @number2, subscribed?: true)

    fm.send_message(from: @number, to: ringer).should be_true
  end

  it 'should return false if it did not send a message to the recipient' do
    tag_filter = Crowdring::TagFilter.create(constraints: ['area code:312'])
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message_text: 'msg')

    ringer = double('ringer', tags: [pittsburgh], phone_number: @number2, subscribed?: true)

    fm.send_message(from: @number, to: ringer).should be_false
  end

  it 'should not send sms to a ringer who is unsubscribed' do
    tag_filter = Crowdring::TagFilter.create(constraints: ['area code:312'])
    chicago = Crowdring::Tag.from_str('area code:312')

    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message_text: 'msg')

    ringer = double('ringer', tags: [chicago], phone_number: @number2, subscribed?: false)
    fm.send_message(from: @number, to: ringer).should be_false
  end

  it 'should not send sms to a ringer who has international phone number' ,focus: true do
    tag_filter = Crowdring::TagFilter.create(constraints: ['area code: 312'])
    chicago = Crowdring::Tag.from_str('area code:312')

    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message_text: 'msg')

    ringer = double('ringer', tags: [chicago], phone_number: '+912222222222', subscribed?: true)
    fm.send_message(from: @number, to: ringer).should be_false
  end
end
