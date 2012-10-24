require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ringer do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
  end

  it 'should not create two ringers with the same phone number' do
    Crowdring::Ringer.create(phone_number: @number1).saved?.should be_true
    Crowdring::Ringer.create(phone_number: @number1).saved?.should be_false
  end

  it 'should not create a ringer with an invalid phone number' do
    Crowdring::Ringer.create(phone_number: 'invalid!').saved?.should be_false
  end

  it 'should destroy all relevant memberships when destroying a ringer' do
    campaign = Crowdring::Campaign.create(title: 'campaign')
    campaign.voice_numbers = [{phone_number: @number1, description: 'num1'}]
    campaign.sms_number = @number2
    campaign.save
    
    ringer = Crowdring::Ringer.create(phone_number: @number1)

    campaign.voice_numbers.first.ring(ringer)
    ringer.destroy

    Crowdring::Ringer.all.count.should eq(0)
    Crowdring::Ring.all.count.should eq(0)
    Crowdring::Campaign.all.count.should eq(1)
  end

  it 'should be tagged with the ringers area code upon creation' do
    ringer = Crowdring::Ringer.create(phone_number: @number1)

    ringer.tags.should include(Crowdring::Tag.from_str('area code:800'))
  end

  it 'should be tagged with the ringers country name upon creation' do
    ringer = Crowdring::Ringer.create(phone_number: @number1)

    ringer.tags.should include(Crowdring::Tag.from_str('country:united states'))
  end

  it 'should interpret numbers with and without a + sign as being the same' do
    r1 = Crowdring::Ringer.from('+18001111111')
    r2 = Crowdring::Ringer.from('18001111111')

    Crowdring::Ringer.count.should eq(1)
    r2.should eq(r1)
  end

  it 'should assume a number without a country code is a US number' do
    r1 = Crowdring::Ringer.from('+18001111111')
    r2 = Crowdring::Ringer.from('8001111111')

    Crowdring::Ringer.count.should eq(1)
    r2.should eq(r1)
  end


end
