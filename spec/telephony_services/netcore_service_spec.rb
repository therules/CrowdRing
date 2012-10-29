require File.dirname(__FILE__) + '/../spec_helper'

describe Crowdring::NetcoreRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:GET) { {'msisdn' => 'from'}}
    r = Crowdring::NetcoreRequest.new(request, 'to')
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::NetcoreRequest.new(request, 'to')
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::NetcoreRequest.new(request, 'to')
    r.callback?.should eq(false)
  end
end