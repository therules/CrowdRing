require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Ivr do

  before(:each) do 
    DataMapper.auto_migrate!
  end
  
  it 'campaign should be able to add a new ivr' do
    params = {"ivr"=>{"auto_text"=>"foo", "keyoption"=>{"1"=>{"press"=>"1", "for"=>"bar"}}}}
    ivr = Crowdring::Ivr.create(params["ivr"])
    ivr.read_text.should eq('foo press 1')
  end

  it 'should create key option object when create a new ivr' do 
    params = {auto_text:"foo", keyoption: {"1" => {press:"1", for: "bar"}}}
    ivr = Crowdring::Ivr.create(params)
    ivr.key_options.count.should eq(1)
  end
end
