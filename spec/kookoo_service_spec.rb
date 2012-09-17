require 'crowdring/kookoo_service'
require 'fakeweb'

describe Crowdring::KooKooService do
  it 'should extract :to and :from from the request' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    extracted = s.extract_params(request)
    extracted[:to].should eq('number')
    extracted[:from].should eq('from')
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

  it 'should GET the right uri on a sendmsg request' do
    s = Crowdring::KooKooService.new('api_key', 'number')
    path = '/outbound/outbound_sms.php?message=msg&phone_no=to&api_key=api_key'
    FakeWeb.register_uri(:get, 'http://www.kookoo.in' + path, body: '')
    s.send_sms(to: 'to', msg: 'msg')
    FakeWeb.last_request.path.should eq(path)
  end

end