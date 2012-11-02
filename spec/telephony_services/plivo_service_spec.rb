require File.dirname(__FILE__) + '/../spec_helper'

describe Crowdring::PlivoRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::PlivoRequest.new(request)
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::PlivoRequest.new(request)
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::PlivoRequest.new(request)
    r.callback?.should eq(false)
  end
end

describe Crowdring::PlivoService do
  before(:each) do
    @service = Crowdring::PlivoService.new('auth_id', 'auth_token')
  end

  it 'should support voice' do
    @service.voice?.should be_true
  end

  it 'should not support sms' do
    @service.sms?.should be_false
  end

  it 'should transform a http request' do
    @service.should respond_to(:transform_request)
  end

  it 'should build a reject response with reason busy' do
    response = @service.build_response('from', [{cmd: :reject}])
    response.should match('<Hangup reason="busy">')
  end

  it 'should be able to record a voicemail' do
    voicemail = double('voicemail', plivo_callback: 'callback')
    response = @service.build_response('from', [{cmd: :record, prompt: 'prompt', voicemail: voicemail}])
    response.should match('<Speak>prompt</Speak>')
    response.should match("<Record action='callback' callbackUrl='callback'/>")
  end
end
