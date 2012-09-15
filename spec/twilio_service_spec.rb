require 'crowdring/twilio_service'

describe Crowdring::TwilioService do
  it 'should extract :to and :from request.POST' do
    service = Crowdring::TwilioService.new('someSid', 'someToken')
    response = double("response")
    response.stub(:POST) { { 'From' => 'from', 'To' => 'to' } }
    extracted = service.extract_params(response)
    extracted[:from].should eq('from')
    extracted[:to].should eq('to')
  end

  it 'should build a reject response with reason busy' do
    service = Crowdring::TwilioService.new('someSid', 'someToken')
    response = service.build_response('from', [{cmd: :reject}])
    response.should eq(Twilio::TwiML::Response.new {|r| r.Reject reason: 'busy'}.text)
  end

  it 'should build a send sms response' do
    service = Crowdring::TwilioService.new('someSid', 'someToken')
    response = service.build_response('from', [{cmd: :sendsms, to: 'to', msg: 'msg'}])
    response.should eq(Twilio::TwiML::Response.new {|r| r.Sms 'msg', from: 'from', to: 'to' }.text)
  end

  it 'should build a response for a series of commands' do
    service = Crowdring::TwilioService.new('someSid', 'someToken')
    cmds = [{cmd: :sendsms, to: 'to', msg: 'msg'},
            {cmd: :reject}]
    response = service.build_response('from', cmds)
    response.should eq(Twilio::TwiML::Response.new do |r| 
      r.Sms 'msg', from: 'from', to: 'to'
      r.Reject reason: 'busy'
    end.text)
  end
end
