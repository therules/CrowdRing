require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ringer do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @intro_response = Crowdring::IntroductoryResponse.create(default_message: 'default')
  end

  it 'should not create two ringers with the same phone number' do
    Crowdring::Ringer.create(phone_number: @number1).saved?.should be_true
    Crowdring::Ringer.create(phone_number: @number1).saved?.should be_false
  end

  it 'should not create a ringer with an invalid phone number' do
    Crowdring::Ringer.create(phone_number: 'invalid!').saved?.should be_false
  end

  it 'should belong to many different campaigns' do
    camp1 = Crowdring::Campaign.create(title: 'camp1', introductory_response: @intro_response, assigned_phone_numbers: [@number2])
    camp2 = Crowdring::Campaign.create(title: 'camp2', introductory_response: @intro_response, assigned_phone_numbers: [@number3])
    ringer = Crowdring::Ringer.create(phone_number: @number1)

    ringer.campaigns << camp1;
    ringer.campaigns << camp2;

    ringer.save.should be_true;
    ringer.campaigns.should include(camp1)
    ringer.campaigns.should include(camp2)
  end

  it 'should destroy all relevant memberships when destroying a ringer' do
    campaign = Crowdring::Campaign.create(title: 'campaign', introductory_response: @intro_response)
    ringer = Crowdring::Ringer.create(phone_number: @number1)
    campaign.join(ringer)
    ringer.destroy

    Crowdring::Ringer.all.count.should eq(0)
    Crowdring::CampaignMembership.all.count.should eq(0)
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
end
