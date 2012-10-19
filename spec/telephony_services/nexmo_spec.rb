require File.dirname(__FILE__) + '/../spec_helper'

describe Crowdring::NexmoRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:GET) { { 'msisdn' => 'from', 'to' => 'to' } }
    r = Crowdring::NexmoRequest.new(request)
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:GET) { { 'msisdn' => 'from', 'to' => 'to' } }
    r = Crowdring::NexmoRequest.new(request)
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:GET) { { 'msisdn' => 'from', 'to' => 'to' } }
    r = Crowdring::NexmoRequest.new(request)
    r.callback?.should eq(false)
  end
end

describe Crowdring::NexmoService do
  before(:each) do
    @service = Crowdring::NexmoService.new('someKey', 'someSecret')
  end

  it 'should support not voice' do
    @service.voice?.should be_false
  end

  it 'should support sms' do
    @service.sms?.should be_true
  end

  it 'should transform a http request' do
    @service.should respond_to(:transform_request)
  end
end

