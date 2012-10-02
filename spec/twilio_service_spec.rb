require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::TwilioRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::TwilioRequest.new(request)
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::TwilioRequest.new(request)
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    r = Crowdring::TwilioRequest.new(request)
    r.callback?.should eq(false)
  end

end


describe Crowdring::TwilioService do
  before(:each) do
    @service = Crowdring::TwilioService.new('someSid', 'someToken')
  end

  it 'should support outgoing' do
    @service.supports_outgoing?.should be_true
  end

  it 'should transform a http request' do
    @service.should respond_to(:transform_request)
  end

  it 'should build a reject response with reason busy' do
    response = @service.build_response('from', [{cmd: :reject}])
    response.should eq(Twilio::TwiML::Response.new {|r| r.Reject reason: 'busy'}.text)
  end

  it 'should build a pause response for the given duration' do
    response = @service.build_response('from', [{cmd: :pause, duration: 10}])
    response.should eq(Twilio::TwiML::Response.new {|r| r.Pause 10}.text)
  end

  it 'should build a send sms response' do
    response = @service.build_response('from', [{cmd: :sendsms, to: 'to', msg: 'msg'}])
    response.should eq(Twilio::TwiML::Response.new {|r| r.Sms 'msg', from: 'from', to: 'to' }.text)
  end

  it 'should build a response for a series of commands' do
    cmds = [{cmd: :sendsms, to: 'to', msg: 'msg'},
            {cmd: :reject}]
    response = @service.build_response('from', cmds)
    response.should eq(Twilio::TwiML::Response.new do |r| 
      r.Sms 'msg', from: 'from', to: 'to'
      r.Reject reason: 'busy'
    end.text)
  end

end
