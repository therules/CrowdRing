require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Supporter do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+11111111111'
    @number2 = '+22222222222'
    @number3 = '+33333333333'
  end

  it 'should not create two supporters with the same phone number' do
    Crowdring::Supporter.create(phone_number: @number1).saved?.should be_true
    Crowdring::Supporter.create(phone_number: @number1).saved?.should be_false
  end

  it 'should not create a supporter with an invalid phone number' do
    Crowdring::Supporter.create(phone_number: 'invalid!').saved?.should be_false
  end

  it 'should belong to many different campaigns' do
    camp1 = Crowdring::Campaign.create(title: 'camp1')
    camp2 = Crowdring::Campaign.create(title: 'camp2')
    supporter = Crowdring::Supporter.create(phone_number: @number1)

    supporter.campaigns << camp1;
    supporter.campaigns << camp2;

    supporter.save.should be_true;
    supporter.campaigns.should include(camp1)
    supporter.campaigns.should include(camp2)
  end

  it 'should destroy all relevant memberships when destroying a supporter' do
    campaign = Crowdring::Campaign.create(title: 'campaign')
    supporter = Crowdring::Supporter.create(phone_number: @number1)
    campaign.join(supporter)
    supporter.destroy

    Crowdring::Supporter.all.count.should eq(0)
    Crowdring::CampaignMembership.all.count.should eq(0)
    Crowdring::Campaign.all.count.should eq(1)
  end
end
