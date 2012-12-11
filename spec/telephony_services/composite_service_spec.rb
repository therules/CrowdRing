require File.dirname(__FILE__) + '/../spec_helper'

describe Crowdring::CompositeService do 

	before(:all) do
		@numbers = ["+18000000000"]
		@numbers2 = ["+18000000001"]
		@service = Crowdring::CompositeService.instance
	end

	before(:each) do
		@service.reset
	end

	it 'should be able to reset itself' do
		service1 = double("foo", numbers: @numbers)
		@service.add("foo", service1)
		@service.reset

		@service.get("foo").should be_nil
	end

	it 'should be able to add and get service' do 
		service1 = double("foo", numbers: @numbers)
		@service.add("foo", service1)
		
		service2 = double("bar", numbers: @numbers2)
		@service.add("bar", service2)
	
		@service.get("foo").should_not be_nil
		@service.get("bar").should_not be_nil
	end

	it 'should return all the numbers from the services which support voice' do
		service1 = double("foo", numbers: ["foo"], voice?: true)
		@service.add("foo", service1)

		service2 = double("bar", numbers: ["bar"], voice?: false)
		@service.add("bar", service2)

		numbers = @service.voice_numbers
		numbers.should eq(["foo"])
	end

	it 'should return all the numbers from the services which support sms' do
		service1 = double("foo", numbers: ["foo"], sms?: true)
		@service.add("foo", service1)

		service2 = double("bar", numbers: ["bar"], sms?: false)
		@service.add("bar", service2)

		numbers = @service.sms_numbers
		numbers.should eq(["foo"])
	end

	describe 'send sms' do

		it 'should send sms using corresponding service' do 
			service1 = double("foo", numbers: ["foo"], sms?: true, send_sms: nil)
			service1.should_receive(:send_sms).once.with(from: 'foo', to: 'bar', msg: 'msg')
			@service.add("foo", service1)

			@service.send_sms(from: 'foo', to: 'bar', msg: 'msg')
		end

		it 'should raise when no services' do
			expect { @service.send_sms(from: 'bar', to: 'bar', msg: 'msg') }.to raise_error(Crowdring::NoServiceError)
		end

		it 'should raise when no supporting service' do
			service2 = double("bar", numbers: ["bar"], sms?: false, send_sms: nil)
			@service.add("bar", service2)

			expect { @service.send_sms(from: 'bar', to: 'bar', msg: 'msg') }.to raise_error(Crowdring::NoServiceError)
		end

	end 
end
