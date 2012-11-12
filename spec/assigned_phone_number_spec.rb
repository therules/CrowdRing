require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::AssignedCampaignVoiceNumber do
  it 'should forward the ring to its associated campaign' do
    campaign = double('campaign', id: 1)
    ringer = double('ringer')
    campaign.should_receive(:ring).once.with(ringer)
    ringer.should_receive(:tag).once

    number = Crowdring::AssignedCampaignVoiceNumber.new(campaign: campaign, phone_number: '+18001111111')
    number.ring(ringer)    
  end
end

describe Crowdring::AssignedSMSNumber do
  it 'should forward the text to its associated campaign' do
    campaign = double('campaign', id: 1)
    ringer = double('ringer')
    message = 'gap'

    campaign.should_receive(:text).once.with(ringer, message)
    number = Crowdring::AssignedSMSNumber.new(campaign: campaign, phone_number: '+18001111111')
    number.text(ringer, message)    
  end
end

describe Crowdring::AssignedPhoneNumber do
  before(:each) do
    DataMapper.auto_migrate!

    @campaign = Crowdring::Campaign.create(title: 'test')
    @campaign.voice_numbers.new(phone_number: '+18001111111', description: 'desc')

    @campaign.sms_number = Crowdring::AssignedSMSNumber.new(phone_number: '+18002222222')
    @campaign.save
  end

  it 'should forward a ring to the correct number' do
    request = double('request', from: '+18003333333', to: '+18001111111')
    Crowdring::AssignedPhoneNumber.handle(:voice, request)

    @campaign.rings.first.ringer.phone_number.should eq('+18003333333')
  end

  it 'should forward a text to the correct number' do
    request = double('request', from: '+18003333333', to: '+18002222222', message: 'message')
    Crowdring::AssignedPhoneNumber.handle(:sms, request)

    @campaign.texts.first.ringer.phone_number.should eq('+18003333333')
  end

  it 'should forward a ring to the correct number when a voice and sms line share a number' do
    @campaign.voice_numbers.new(phone_number: '+18002222222', description: 'same as sms')
    @campaign.save

    request = double('request', from: '+18003333333', to: '+18002222222')
    Crowdring::AssignedPhoneNumber.handle(:voice, request)

    @campaign.rings.first.ringer.phone_number.should eq('+18003333333')
  end

  it 'should forward a text to the correct number when a voice and sms line share a number' do
    @campaign.voice_numbers.new(phone_number: '+18002222222', description: 'same as sms')
    @campaign.save

    request = double('request', from: '+18003333333', to: '+18002222222', message: 'message')
    Crowdring::AssignedPhoneNumber.handle(:sms, request)

    @campaign.texts.first.ringer.phone_number.should eq('+18003333333')
  end
end

describe Crowdring::AssignedUnsubscribeVoiceNumber do
  before(:each) do
    DataMapper.auto_migrate!
    Crowdring::AssignedUnsubscribeVoiceNumber.create(phone_number: '+18002222222')
  end

  it 'should unsubscribe a ringer when calls' do
    Crowdring::Ringer.create(phone_number: '+18000000000')
    request = double('request', from: '+18000000000', to:'+18002222222')
    Crowdring::AssignedPhoneNumber.handle(:voice, request)

    Crowdring::Ringer.first.unsubscribed?.should be_true
  end

  it 'should re-subscribe a ringer when calls after unsubscribing' do
    @campaign = Crowdring::Campaign.create(title: 'test')
    @campaign.voice_numbers.new(phone_number: '+18001111111', description: 'desc')
    @campaign.sms_number = Crowdring::AssignedSMSNumber.new(phone_number: '+18002222222')
    @campaign.save

    Crowdring::Ringer.create(phone_number: '+18000000000', subscribed: false)
    request = double('request', from: '+18000000000', to:'+18001111111')
    Crowdring::AssignedPhoneNumber.handle(:voice, request)

    Crowdring::Ringer.first.subscribed?.should be_true
  end
end
