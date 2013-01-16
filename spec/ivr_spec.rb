require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ivr do

  include Rack::Test::Methods

  def app
    Crowdring::Server
  end

  before(:each) do 
    DataMapper.auto_migrate!
  end
  
  it 'campaign should be able to add a new ivr' do
    params = {"ivr"=>{"auto_text"=>"foo", "keyoption"=>{"1"=>{"press"=>"1", "for"=>"bar"}}}}
    ivr = Crowdring::Ivr.create(params["ivr"])
    Crowdring::Ivr.last.read_text.should match('foo press 1')
  end

  it 'should create key option object when create a new ivr' do 
    params = {auto_text:"foo", keyoption: {"1" => {press:"1", for: "bar"}}}
    ivr = Crowdring::Ivr.create(params)
    ivr.key_options.count.should eq(1)
  end

  it 'should set question' do 
    params = {"ivr"=>{"auto_text"=>"foo", "keyoption"=>{"1"=>{"press"=>"1", "for"=>"bar"}}}}
    ivr = Crowdring::Ivr.create(params["ivr"])
    Crowdring::Ivr.last.question.should eq('foo')
  end

  it 'should be able to update ringer count' do 
    params = {auto_text:"foo", keyoption: {"1" => {press:"1", for: "bar"}, "2" => {press:'2', for: 'foo'}}}
    ivr = Crowdring::Ivr.create(params)
    campaign = Crowdring::Campaign.create(title: 'c3', voice_numbers: [{phone_number: '+18003333333', description: "c3 num"}], sms_number: '+18003333333')
    campaign.ivrs << ivr
    campaign.save

    params = {Digits: '1', id: 1}
    post '/ivrs/1/collect_digit', params
    campaign.ivrs.last.key_options.first.ringer_count.should eq(1)
  end

  it 'should be able to disable ivr' do
    params = {auto_text:"foo", keyoption: {"1" => {press:"1", for: "bar"}, "2" => {press:'2', for: 'foo'}}}
    ivr = Crowdring::Ivr.create(params)
    campaign = Crowdring::Campaign.create(title: 'c3', voice_numbers: [{phone_number: '+18003333333', description: "c3 num"}], sms_number: '+18003333333')
    campaign.ivrs << ivr
    campaign.save
   
    post "/campaign/#{campaign.id}/ivrs/disable"
    ivr.reload
    ivr.activated.should be_false
  end
end
