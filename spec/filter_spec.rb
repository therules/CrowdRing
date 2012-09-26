require 'crowdring/filter'
require 'phone'

describe 'filters' do
  it 'should return all of the given elements' do
    filter = Crowdring::Filter.create('all')
    filter.filter([1,2,3]).should eq([1,2,3])
  end

  it 'should return the elements created after a given date' do
    oldOne = double('old', created_at: DateTime.now - 2)
    newOne = double('new', created_at: DateTime.now)
    filter = Crowdring::Filter.create("after:#{DateTime.now - 1}")
    filter.filter([oldOne, newOne]).should eq([newOne])
  end

  it 'should return the elements matching the given country code' do
    numOne = double('US', country: Phoner::Country.find_by_country_code('1'))
    numTwo = double('IN', country: Phoner::Country.find_by_country_code('91'))
    filter = Crowdring::Filter.create("country:US")
    filter.filter([numOne, numTwo]).should eq([numOne])
  end

  it 'should accept multiple country codes separated by bars' do
    numOne = double('US', country: Phoner::Country.find_by_country_code('1'))
    numTwo = double('IN', country: Phoner::Country.find_by_country_code('91'))
    filter = Crowdring::Filter.create("country:US|IN")
    filter.filter([numOne, numTwo]).should eq([numOne, numTwo])
  end
end