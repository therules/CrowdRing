require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::AggregateCampaign do
  before(:each) do
    DataMapper.auto_migrate!

    @c1 = Crowdring::Campaign.create(title: 'c1', voice_numbers: [{phone_number: '+18001111111', description: "c1 num"}], sms_number: '+18001111111')
    @c2 = Crowdring::Campaign.create(title: 'c2', voice_numbers: [{phone_number: '+18002222222', description: "c2 num"}], sms_number: '+18002222222')
    @c3 = Crowdring::Campaign.create(title: 'c3', voice_numbers: [{phone_number: '+18003333333', description: "c3 num"}], sms_number: '+18003333333')
  end

  it 'should be created with a list of campaigns' do

    ac = Crowdring::AggregateCampaign.create(name: 'ac', campaigns: [@c1.id, @c2.id, @c3.id])

    ac.campaigns.count.should eq(3)
    ac.campaigns.should include(@c1)
    ac.campaigns.should include(@c2)
    ac.campaigns.should include(@c3)
  end

  it 'should aggregate the ringer counts from each campaign' do
    r1 = Crowdring::Ringer.create(phone_number: '+18881111111')
    r2 = Crowdring::Ringer.create(phone_number: '+18882222222')
    r3 = Crowdring::Ringer.create(phone_number: '+18883333333')
    r4 = Crowdring::Ringer.create(phone_number: '+18884444444')

    @c1.voice_numbers.first.ring(r1)
    @c2.voice_numbers.first.ring(r2)
    @c3.voice_numbers.first.ring(r3)
    @c1.voice_numbers.first.ring(r4)

    ac = Crowdring::AggregateCampaign.create(name: 'ac', campaigns: [@c1, @c2, @c3])

    ac.ringer_count.should eq(4)
  end
end
