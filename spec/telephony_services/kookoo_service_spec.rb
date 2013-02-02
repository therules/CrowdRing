require File.dirname(__FILE__) + '/../spec_helper'

describe Crowdring::KooKooRequest do
  it 'should extract the from parameter' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::KooKooRequest.new(request)
    r.from.should eq('from')
  end


  it 'should not be a callback' do
    request = double("request")
    request.stub(:GET) { {'cid' => 'from'}}
    r = Crowdring::KooKooRequest.new(request)
    r.callback?.should eq(false)
  end
end

describe Crowdring::KooKooService do
  before(:each) do
    @service = Crowdring::KooKooService.new('api_key')
  end   

  it 'should support voice' do
    @service.voice?.should be_true
  end
  it 'should not support sms' do
    @service.sms?.should be_true
  end
  
  it 'should transform a http request' do
    @service.should respond_to(:transform_request)
  end

  it 'should build a reject response' do
    response = @service.build_response('from', [{cmd: :reject}])
    response.should include('<hangup>')  end


  it 'should return a list of the available numbers' do
    @service.numbers.count.should eq(1)
  end

  it 'should GET the right uri on send_msg' do
    path = '/outbound/outbound_sms.php?message=msg&phone_no=to&api_key=api_key'
    FakeWeb.register_uri(:get, 'http://www.kookoo.in' + path, body: '')
    @service.send_sms(to: 'to', msg: 'msg')
    FakeWeb.last_request.path.should eq(path)
  end

end