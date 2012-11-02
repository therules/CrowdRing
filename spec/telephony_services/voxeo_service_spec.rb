require File.dirname(__FILE__) + '/../spec_helper'


describe Crowdring::VoxeoRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:GET) { { 'callerID' => 'from', 'calledID' => 'to' } }
    r = Crowdring::VoxeoRequest.new(request)
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:GET) { { 'callerID' => 'from', 'calledID' => 'to' } }
    r = Crowdring::VoxeoRequest.new(request)
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:GET) { { 'callerID' => 'from', 'calledID' => 'to' } }
    r = Crowdring::VoxeoRequest.new(request)
    r.callback?.should eq(false)
  end
end

describe Crowdring::VoxeoService do
  before(:each) do
    @service = Crowdring::VoxeoService.new('app_id', 'uname', 'pword')
  end

  it 'should support voice' do
    @service.voice?.should be_true
  end

  it 'should not support sms' do
    @service.sms?.should be_false
  end

  it 'should transform a http requst' do
    @service.should respond_to(:transform_request)
  end

  it 'should build a reject response' do
    response = @service.build_response('from', [{cmd: :reject}])
    response.should match('<reject />')
  end

  it 'should build a record response using the correct filename and prompt' do
    voicemail = double('voicemail', filename: 'filename')
    response = @service.build_response('from', [{cmd: :record, prompt: 'prompt', voicemail: voicemail}])
    response.should match("<answer><do><prompt value='prompt'/><recordaudio value='filename' format='audio/wav' /></do></answer>")
  end

end