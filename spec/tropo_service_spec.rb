require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::TropoRequest do
  it 'should extract the from parameter' do
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}}}')
    request.stub(:body) { body }
    r = Crowdring::TropoRequest.new(request)
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}}}')
    request.stub(:body) { body }
    r = Crowdring::TropoRequest.new(request)
    r.to.should eq('to')
  end

  it 'should recognize normal request as not being a callback' do
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}}}')
    request.stub(:body) { body }
    r = Crowdring::TropoRequest.new(request)
    r.callback?.should eq(false)
  end

  it 'should recognize callback request as being a callback' do
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}, "parameters":{}}}')
    request.stub(:body) { body }
    r = Crowdring::TropoRequest.new(request)
    r.callback?.should eq(true)
  end

  it 'should extract to, from, and msg from a callback request' do
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}, "parameters":{"to":"to", "from":"from", "msg":"msg"}}}')
    request.stub(:body) { body }
    r = Crowdring::TropoRequest.new(request)
    r.to.should eq("to")
    r.from.should eq("from")
    r.msg.should eq("msg")
  end
end


describe Crowdring::TropoService do
  before(:each) do
    @service = Crowdring::TropoService.new('msg_token', 'app_id', 'uname', 'pword')
  end

  it 'should support outgoing' do
    @service.supports_outgoing?.should be_true
  end

  it 'should transform a http requst' do
    @service.should respond_to(:transform_request)
  end

  it 'should build a reject response' do
    response = @service.build_response('from', [{cmd: :reject}])
    response.should eq(Tropo::Generator.new { reject }.response)
  end

  it 'should build a send sms response' do
    response = @service.build_response('from', [{cmd: :sendsms, to: 'to', msg: 'msg'}])
    response.should eq(Tropo::Generator.new { message(to: 'to', network: 'SMS', channel: 'TEXT') { say 'msg' }}.response)
  end

  it 'should build a response for a series of commands' do
    cmds = [{cmd: :sendsms, to: 'to', msg: 'msg'},
            {cmd: :reject}]
    response = @service.build_response('from', cmds)
    response.should eq(Tropo::Generator.new do
      message(to: 'to', network: 'SMS', channel: 'TEXT') { say 'msg' }
      reject
    end.response)
  end

  it 'should process a callback by sending an sms' do
    request = double("request")
    request.stub(:from){'from'}
    request.stub(:to){'to'}
    request.stub(:msg){'msg'}
    request.stub(:callback?){true}
    response = @service.process_callback(request)
    response.should eq(Tropo::Generator.new { message(to: 'to', network: 'SMS', channel: 'TEXT') { say 'msg' }}.response)
  end

  it 'should GET the right uri on send_msg' do
    path = '/1.0/sessions?action=create&token=msg_token&from=from&to=to&msg=msg'
    FakeWeb.register_uri(:get, 'http://api.tropo.com' + path, body: '')
    @service.send_sms(from: 'from', to: 'to', msg: 'msg')
    FakeWeb.last_request.path.should eq(path)
  end
end