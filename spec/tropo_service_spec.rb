require 'crowdring/tropo_service'

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
  it 'should transform a http requst' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    service.should respond_to(:transform_request)
  end

  it 'should build a reject response' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    response = service.build_response('from', [{cmd: :reject}])
    response.should eq(Tropo::Generator.new { reject }.response)
  end

  it 'should build a send sms response' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    response = service.build_response('from', [{cmd: :sendsms, to: 'to', msg: 'msg'}])
    response.should eq(Tropo::Generator.new { message(to: 'to', network: 'SMS', channel: 'TEXT') { say 'msg' }}.response)
  end

  it 'should build a response for a series of commands' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    cmds = [{cmd: :sendsms, to: 'to', msg: 'msg'},
            {cmd: :reject}]
    response = service.build_response('from', cmds)
    response.should eq(Tropo::Generator.new do
      message(to: 'to', network: 'SMS', channel: 'TEXT') { say 'msg' }
      reject
    end.response)
  end


end