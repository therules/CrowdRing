require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::CompositeService do 

	before(:all) do
		@service = Crowdring::CompositeService.instance
	end

	before(:each) do
		@service.reset
	end

	it 'should be able to reset itself' do
		service1 = double("foo")
		@service.add("foo", service1)
		@service.reset

		@service.get("foo").should be_nil
	end

	it 'should be able to add and get service' do 
		service1 = double("foo")
		@service.add("foo", service1)
		
		service2 = double("bar")
		@service.add("bar", service2)
	
		@service.get("foo").should eq(service1)
		@service.get("bar").should eq(service2)
	end

	it 'should return all the numbers from the services' do 
		 service1 = double("foo", numbers: ["foo"])
		 service1.should_receive(:numbers).once
		 @service.add("foo", service1)
		
		 service2 = double("bar", numbers: ["bar"])
		 service2.should_receive(:numbers).once
		 @service.add("bar", service2)
		 
		 numbers = @service.numbers
		 numbers.should include("foo")
		 numbers.should include("bar")
	end

	describe 'send sms' do

		it 'should send sms using corresponding service' do 
			service1 = double("foo", numbers: ["foo"], supports_outgoing?: true, send_sms: nil)
			service1.should_receive(:send_sms).once.with(from: 'foo', to: 'bar', msg: 'msg')
			@service.add("foo", service1)

			@service.send_sms(from: 'foo', to: 'bar', msg: 'msg')
		end

		it 'should send sms using default service' do
			service1 = double("foo", numbers: ["foo"], supports_outgoing?: true, send_sms: nil)
			service1.should_receive(:send_sms).once.with(from: 'foo', to: 'bar', msg: 'msg')
			@service.add("foo", service1, default: true)

			service2 = double("bar", numbers: ["bar"], supports_outgoing?: false, send_sms: nil)
			service2.should_not_receive(:send_sms)
			@service.add("bar", service2)
	
			@service.send_sms(from: 'bar', to: 'bar', msg: 'msg')
		end

		it 'should raise when no services' do
			expect { @service.send_sms(from: 'bar', to: 'bar', msg: 'msg') }.to raise_error(Crowdring::NoServiceError)
		end

		it 'should raise when no supporting service' do
			service2 = double("bar", numbers: ["bar"], supports_outgoing?: false, send_sms: nil)
			@service.add("bar", service2)

			expect { @service.send_sms(from: 'bar', to: 'bar', msg: 'msg') }.to raise_error(Crowdring::NoServiceError)
		end

	end 
end
