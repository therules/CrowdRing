require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Campaign do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @c = Crowdring::Campaign.create(title: 'test')
  end

  it 'should create a campaign with a voice number and a sms number' do
    @campaign = Crowdring::Campaign.create(title: 'test', voice_number: @number1, sms_number: @number2)

    @campaign.save.should be_true    
    @campaign.voice_number.should eq(Crowdring::AssignedVoiceNumber.first)
    @campaign.sms_number.should eq(Crowdring::AssignedSMSNumber.first)
  end

  it 'should remove the assigned numbers on campaign destruction' do
    @c.voice_number = @number1
    @c.sms_number = @number2
    @c.save

    @c.destroy.should be_true
    Crowdring::AssignedVoiceNumber.all.should be_empty
    Crowdring::AssignedSMSNumber.all.should be_empty
  end

  it 'should not allow assignment of an invalid phone number' do
    @c.voice_number = 'badger, badger'
    @c.save.should be_false
  end

  it 'should not allow assigning the same number to multiple campaigns' do
    c1 = Crowdring::Campaign.create(title: 'test', message: Crowdring::Message.create(default_message:'intro msg'))
    c1.voice_number = @number1
    c1.save

    c2 = Crowdring::Campaign.create(title: 'test2', message: Crowdring::Message.create(default_message:'intro msg'))
    c2.voice_number = @number1
    
    c2.save.should be_false   
  end

  it 'should have many ringers' do
    @c.voice_number = @number3
    @c.save

    r1 = Crowdring::Ringer.create(phone_number: @number1)
    r2 = Crowdring::Ringer.create(phone_number: @number2)
    @c.rings.create(ringer: r1)
    @c.rings.create(ringer: r2)

    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number1))
    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number2))
  end

  it 'should track the original date a ringer supported a campaign' do
    @c.voice_number = @number3
    @c.save

    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.voice_number.ring(r)

    @c.rings.first.created_at.to_date.should eq(Date.today)
  end

  it 'should track all of the times a ringer rings a campaign' do
    @c.voice_number = @number3
    @c.save
    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.voice_number.ring(r)
    @c.voice_number.ring(r)

    @c.rings.count.should eq(2)
  end

  it 'should remove rings when a campaign is destroyed' do
    @c.voice_number = @number3
    @c.save
    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.voice_number.ring(r)
    @c.destroy

    Crowdring::Ring.all.should be_empty
    Crowdring::Ringer.all.count.should eq(1)
  end
end
