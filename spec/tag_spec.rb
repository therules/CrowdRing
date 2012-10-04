require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Tag do
  before(:each) do
    DataMapper.auto_migrate!
  end

  it 'should lookup a tag from a string representation of it' do
    Crowdring::Tag.create(type: 'area code', value: '412')
    tag = Crowdring::Tag.from_str('area code:412')
    tag.should_not be_nil
    tag.type.should eq('area code')
    tag.value.should eq('412')
    Crowdring::Tag.all.count.should eq(1)
  end

  it 'should create a new tag when looking up from a string rep if it doesnt exist' do
    tag = Crowdring::Tag.from_str('area code:412')
    tag.should_not be_nil
    tag.type.should eq('area code')
    tag.value.should eq('412')
    Crowdring::Tag.all.count.should eq(1)
  end

  it 'should ignore case when performing lookups' do
    Crowdring::Tag.create(type: 'area code', value: 'fouronetwo')
    tag = Crowdring::Tag.from_str('AREA Code:FOURoneTWO')
    tag.should_not be_nil
    tag.type.should eq('area code')
    tag.value.should eq('fouronetwo')
    Crowdring::Tag.all.count.should eq(1)
  end

  it 'should always downcase the type and value' do
    Crowdring::Tag.create(type: 'AREA Code', value: 'FOURoneTWO')
    tag = Crowdring::Tag.from_str('area code:fouronetwo')
    tag.should_not be_nil
    tag.type.should eq('area code')
    tag.value.should eq('fouronetwo')
    Crowdring::Tag.all.count.should eq(1)    
  end

end