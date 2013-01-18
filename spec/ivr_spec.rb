require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ivr do

  include Rack::Test::Methods

  def app
    Crowdring::Server
  end

  before(:each) do 
    DataMapper.auto_migrate!
    @params = {"question"=>"foo", "key_options"=>{"1"=>{"press"=>"1", "for"=>"bar"}}}
    @ivr = Crowdring::Ivr.create(@params)
    @stub_campaign = double('campaign', id: 1, ivrs: @ivr)

  end
  
  it '@campaign should be able to add a new ivr' do
    Crowdring::Ivr.last.read_text.should match('foo press 1 for bar')
  end

  it 'should create key option object when create a new ivr' do 
    Crowdring::KeyOption.all.count.should eq(1)
  end

  it 'should set question' do 
    Crowdring::Ivr.last.question.should eq('foo')
  end

  describe 'when having an activated ivr' do
    before(:each) do
      @campaign = Crowdring::Campaign.create(title: 'c3', voice_numbers: [{phone_number: '+18003333333', description: "c3 num"}], sms_number: '+18003333333')
      @campaign.ivrs << @ivr
      @campaign.save
    end

    it 'should be able to update ringer count' do 
      params = {Digits: '1', id: 1}
      post "/ivrs/#{@campaign.id}/collect_digit", params

      Crowdring::KeyOption.first.ringer_count.should eq(1)
    end

    it 'should be able to disable ivr' do
      post "/campaign/#{@campaign.id}/ivrs/disable"

      Crowdring::Ivr.first.activated.should be_false
    end

    it 'should be able to destroy ivr' do
      post "/campaign/#{@campaign.id}/ivrs/#{@ivr.id}/destroy"
      Crowdring::Ivr.all.count.should eq(0)
    end
  end
end