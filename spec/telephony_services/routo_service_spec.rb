require File.dirname(__FILE__) + '/../spec_helper'
require 'fakeweb'
describe Crowdring::RoutoService do
  before(:each) do
    @service = Crowdring::RoutoService.new('user', 'password', 'TEST Number')
  end

  it 'should support not voice' do
    @service.voice?.should be_false
  end

  it 'should support sms' do
    @service.sms?.should be_true
  end

  it 'should use the back up uri when the default uri failed' do 
    FakeWeb.register_uri(:get, %r|.smsc5.|, body: 'failed')
    FakeWeb.register_uri(:get, %r|.smsc6.|, body: 'I AM HERE')
    
    res = @service.send_sms(to:'to', from: 'from',msg: 'msg')
    res.body.should eq('I AM HERE')
  end
end
