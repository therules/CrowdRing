require File.dirname(__FILE__) + '/../spec_helper'

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
end
