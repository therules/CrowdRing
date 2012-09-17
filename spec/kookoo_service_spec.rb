require 'crowdring/kookoo_service'
require 'fakeweb'

describe Crowdring::KooKooRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::KooKooRequest.new(request, 'to')
    r.from.should eq('from')
  end

  it 'should extract the to parameter' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::KooKooRequest.new(request, 'to')
    r.to.should eq('to')
  end

  it 'should not be a callback' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::KooKooRequest.new(request, 'to')
    r.callback?.should eq(false)
  end
end

describe Crowdring::KooKooService do
  it 'should transform a http request' do
    service = Crowdring::KooKooService.new('someSid', 'someToken')
    service.should respond_to(:transform_request)
  end

  it 'should build a reject response' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    response = s.build_response('from', [{cmd: :reject}])
    response.should eq(Builder::XmlMarkup.new(indent: 2).response { |r| r.hangup })
  end

  it 'should build a send sms response' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    response = s.build_response('from', [{cmd: :sendsms, to: 'to', msg: 'msg'}])
    response.should eq(Builder::XmlMarkup.new(indent: 2).response { |r| r.sendsms 'msg', to: 'to'})
  end

  it 'should build a response for a series of commands' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    cmds = [{cmd: :sendsms, to: 'to', msg: 'msg'},
            {cmd: :reject}]
    response = s.build_response('from', cmds)
    response.should eq(Builder::XmlMarkup.new(indent: 2).response do |r|
      r.sendsms 'msg', to: 'to'
      r.hangup
    end)
  end

  it 'should return a list of the available numbers' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    s.numbers.should eq(['number'])
  end

  it 'should GET the right uri on send_msg' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    path = '/outbound/outbound_sms.php?message=msg&phone_no=to&api_key=api_key'
    FakeWeb.register_uri(:get, 'http://www.kookoo.in' + path, body: '')
    s.send_sms(to: 'to', msg: 'msg')
    FakeWeb.last_request.path.should eq(path)
  end

end