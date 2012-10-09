require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::FilteredMessage do
  before(:each) do
    DataMapper.auto_migrate!

    @number = '+18001111111'
    @number2 = '+18002222222'
    @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
    @fooservice = double('fooservice', build_response: 'fooResponse',
        supports_outgoing?: true,
        transform_request: @fooresponse,
        numbers: [@number],
        send_sms: nil)
    Crowdring::CompositeService.instance.reset
    Crowdring::CompositeService.instance.add('foo', @fooservice)
  end

  it 'should send a message to an accepted recipient' do
    tag_filter = Crowdring::TagFilter.create
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    tag_filter.tags << pittsburgh
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message: 'msg')

    item1 = double('item1', tags: [pittsburgh], phone_number: @number2)

    @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'msg')
    fm.send_message(from: @number, to: item1)
  end

  it 'should return true if it sent a message to the recipient' do
    tag_filter = Crowdring::TagFilter.create
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    tag_filter.tags << pittsburgh
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message: 'msg')

    item1 = double('item1', tags: [pittsburgh], phone_number: @number2)

    fm.send_message(from: @number, to: item1).should be_true
  end

  it 'should return false if it did not send a message to the recipient' do
    tag_filter = Crowdring::TagFilter.create
    pittsburgh = Crowdring::Tag.from_str('area code:412')
    chicago = Crowdring::Tag.from_str('area code:312')
    tag_filter.tags << chicago
    fm = Crowdring::FilteredMessage.create(tag_filter: tag_filter, priority: 1, message: 'msg')

    item1 = double('item1', tags: [pittsburgh], phone_number: @number2)

    fm.send_message(from: @number, to: item1).should be_false
  end

end
