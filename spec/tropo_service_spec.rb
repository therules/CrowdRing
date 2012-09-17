require 'crowdring/tropo_service'

describe Crowdring::TropoService do
  it 'should extract :to and :from from the request body' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    request = double("request")
    body = StringIO.new('{"session":{"from":{"name":"from"}, "to":{"name":"to"}}}')
    request.stub(:body) { body }
    extracted = service.extract_params(request)
    extracted[:to].should eq('to')
    extracted[:from].should eq('from')
  end

  it 'should restore the request after extracting params' do
    service = Crowdring::TropoService.new('msg_token', 'app_id')
    request = double("request")
    body_str = '{"session":{"from":{"name":"from"}, "to":{"name":"to"}}}'
    body = StringIO.new(body_str)
    request.stub(:body) { body }
    extracted = service.extract_params(request)
    body.read.should eq(body_str)
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