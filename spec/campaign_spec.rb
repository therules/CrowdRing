require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Campaign do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+11111111111'
    @number2 = '+22222222222'
    @c = Crowdring::Campaign.create(title: 'test', introductory_response: @intro_response)
  end

  it 'should create a campaign with multiple assigned phone numbers' do
    
    @c.assigned_phone_numbers.create(phone_number: @number1)
    @c.assigned_phone_numbers.create(phone_number: @number2)

    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number2))
  end

  it 'should remove the assigned numbers on campaign destruction' do
    @c.assigned_phone_numbers.create(phone_number: @number1)
    @c.destroy.should be_true
    Crowdring::AssignedPhoneNumber.all.should be_empty
  end

  it 'should easily assign multiple numbers given the raw numbers' do
    @c.assign_phone_numbers([@number1, @number2]).should be_true

    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number2))
  end

  it 'should signify if assigning multiple raw numbers fails' do
    @c.assign_phone_numbers([@number1, @number1]).should be_false
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
  end

  it 'should assign all the valid phone numbers provided' do
    @c.assign_phone_numbers([@number1, 'foobar', @number1, @number2]).should be_false
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number2))
    @c.assigned_phone_numbers.count.should eq(2)
  end

  it 'should not allow assignment of an invalid phone number' do
    @c.assigned_phone_numbers.create(phone_number: 'badnumber').saved?.should be_false
  end

  it 'should not allow assigning the same number to multiple campaigns' do
    c1 = Crowdring::Campaign.create(title: 'test', introductory_response: Crowdring::IntroductoryResponse.create_with_default('intro msg'))
    c1.assigned_phone_numbers.create(phone_number: @number1)
    c2 = Crowdring::Campaign.create(title: 'test2', introductory_response: Crowdring::IntroductoryResponse.create_with_default('intro msg'))
    expect {c2.assigned_phone_numbers.create(phone_number: @number1)}.to raise_error(DataObjects::IntegrityError)
  end

  it 'should have many ringers' do
    @c.ringers.create(phone_number: @number1)
    @c.ringers.create(phone_number: @number2)

    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number1))
    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number2))
  end

  it 'should track the original date a ringer supported a campaign' do
    s = Crowdring::Ringer.create(phone_number: @number2)
    @c.join(s)

    @c.memberships.first.created_at.to_date.should eq(Date.today)
  end

  it 'should track a ringers most recent support of a campaign' do
    s = Crowdring::Ringer.create(phone_number: @number2)
    @c.join(s)
    first_join = @c.memberships.first.updated_at
    @c.join(s)

    membership = @c.memberships.first
    first_join.should be < membership.updated_at
  end

  it 'should track the number of times a ringer calls into a campaign' do
    s = Crowdring::Ringer.create(phone_number: @number2)
    @c.join(s)
    @c.join(s)
    @c.join(s)

    @c.memberships.first.count.should eq(3)    
  end

  it 'should remove memberships when a campaign is destroyed' do
    s = Crowdring::Ringer.create(phone_number: @number2)
    @c.join(s)
    @c.destroy

    Crowdring::CampaignMembership.all.should be_empty
    Crowdring::Ringer.all.count.should eq(1)
  end

  it 'should give the total number of rings, including non-unique' do
    r1 = Crowdring::Ringer.create(phone_number: @number1)
    r2 = Crowdring::Ringer.create(phone_number: @number2)

    @c.join(r1)
    @c.join(r2)
    @c.join(r1)
    @c.join(r1)

    @c.ring_count.should eq(4)
  end
end
