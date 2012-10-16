require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Campaign do
  before(:each) do
    DataMapper.auto_migrate!
    @number1 = '+18001111111'
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @c = Crowdring::Campaign.create(title: 'test')
  end

  it 'should create a campaign with multiple assigned phone numbers' do
    @c.assigned_phone_numbers = [@number1, @number2]
    @c.save

    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number2))
  end

  it 'should remove the assigned numbers on campaign destruction' do
    @c.assigned_phone_numbers.create(phone_number: @number1)
    @c.destroy.should be_true
    Crowdring::AssignedPhoneNumber.all.should be_empty
  end

  it 'should easily assign multiple numbers given the raw numbers' do
    @c.assigned_phone_numbers = [@number1, @number2]
    @c.save

    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number1))
    @c.assigned_phone_numbers.should include(Crowdring::AssignedPhoneNumber.get(@number2))
  end

  it 'should not allow assignment of an invalid phone number' do
    @c.assigned_phone_numbers.create(phone_number: 'badnumber').saved?.should be_false
  end

  it 'should not allow assigning the same number to multiple campaigns' do
    c1 = Crowdring::Campaign.create(title: 'test', message: Crowdring::Message.create(default_message:'intro msg'))
    c1.assigned_phone_numbers.create(phone_number: @number1)
    c2 = Crowdring::Campaign.create(title: 'test2', message: Crowdring::Message.create(default_message:'intro msg'))
    expect {c2.assigned_phone_numbers.create(phone_number: @number1)}.to raise_error(DataObjects::IntegrityError)
  end

  it 'should have many ringers' do
    @c.assigned_phone_numbers = [@number3]
    @c.save
    r1 = Crowdring::Ringer.create(phone_number: @number1)
    r2 = Crowdring::Ringer.create(phone_number: @number2)
    @c.rings.create(ringer: r1, number_rang: @c.assigned_phone_numbers.first)
    @c.rings.create(ringer: r2, number_rang: @c.assigned_phone_numbers.first)

    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number1))
    @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number2))
  end

  it 'should track the original date a ringer supported a campaign' do
    @c.assigned_phone_numbers = [@number3]
    @c.save
    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.assigned_phone_numbers.first.ring(r)

    @c.rings.first.created_at.to_date.should eq(Date.today)
  end

  it 'should track all of the times a ringer rings a campaign' do
    @c.assigned_phone_numbers = [@number3]
    @c.save
    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.assigned_phone_numbers.first.ring(r)
    @c.assigned_phone_numbers.first.ring(r)

    @c.rings.count.should eq(2)
  end

  it 'should remove rings when a campaign is destroyed' do
    @c.assigned_phone_numbers = [@number3]
    @c.save
    r = Crowdring::Ringer.create(phone_number: @number2)
    @c.assigned_phone_numbers.first.ring(r)
    @c.destroy

    Crowdring::Ring.all.should be_empty
    Crowdring::Ringer.all.count.should eq(1)
  end

end
