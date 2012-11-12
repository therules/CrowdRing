require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::NumberPool do
  before(:each) do
    DataMapper.auto_migrate!
    Crowdring::CompositeService.instance.reset

    Crowdring::CompositeService.instance.add('logger', Crowdring::LoggingService.new([
      '+18001111111', '+18002222222', '+919000764614', '+919010764614', '+27114891907', '+917353764614']))
  end

  it 'should return an array summarizing the available numbers' do
    numbers = Crowdring::NumberPool.available_summary
    numbers.should include({country: 'United States', count: 2})
  end

  it 'should break down the numbers in a country by region if possible' do
    numbers = Crowdring::NumberPool.available_summary
    numbers.should include({country: 'India', region: 'Andhra Pradesh', count: 2})
    numbers.should include({country: 'India', region: 'Karnataka', count: 1})
  end

  it 'should not contain duplicate entries' do
    numbers = Crowdring::NumberPool.available_summary
    numbers.select {|n| n == {country: 'United States', count: 2}}.count.should eq(1)
  end

  it 'should not include an assigned number' do
    Crowdring::AssignedVoiceNumber.create(phone_number: '+18001111111').saved?.should be_true
    numbers = Crowdring::NumberPool.available_summary
    numbers.should include({country: 'United States', count: 1})
  end

  it 'should return phone number that comes from required country' do
    opts = [{country: 'United States'}]
    Crowdring::NumberPool.find_numbers(opts).should eq(['+18001111111'])
  end

  it 'should return phone number that comes from required country and region' do
    opts = [{country: 'India', region: 'Karnataka'}]
    Crowdring::NumberPool.find_numbers(opts).should eq(['+917353764614'])
  end

  it 'should return unique numbers from same criteria' do
    opts = [{country: 'United States'},{country: 'United States'}]
    numbers = Crowdring::NumberPool.find_numbers(opts)
    numbers.should include('+18001111111')
    numbers.should include('+18002222222')
  end
end
