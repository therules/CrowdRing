require File.dirname(__FILE__) + '/spec_helper'

describe Crowdring::Campaign do

  def app
    Crowdring::Server
  end


  describe 'campaign creation' do
    before(:each) do
      DataMapper.auto_migrate!
      @number1 = {phone_number: '+18001111111', description: 'num1'}
      @number2 = '+18002222222'
      @number3 = '+18003333333'
      @c = Crowdring::Campaign.create(title: 'test')
    end

    it 'should create a campaign with a voice number and a sms number' do
      @campaign = Crowdring::Campaign.create(title: 'test', voice_numbers: [@number1], sms_number: @number2)

      @campaign.save.should be_true    
      @campaign.voice_numbers.first.should eq(Crowdring::AssignedVoiceNumber.first)
      @campaign.sms_number.should eq(Crowdring::AssignedSMSNumber.first)
    end
   
    it 'should remove the assigned numbers on campaign destruction' do
      @c.voice_numbers.new(@number1)
      @c.sms_number = @number2
      @c.save

      @c.destroy.should be_true
      Crowdring::AssignedCampaignVoiceNumber.all.should be_empty
      Crowdring::AssignedSMSNumber.all.should be_empty
    end

    it 'should not allow assignment of an invalid phone number' do
      @c.voice_numbers.new({phone_number:'badger, badger', description: 'nonsense'})
      @c.save.should be_false
    end

    it 'should not allow assigning the same number to multiple campaigns' do
      c1 = Crowdring::Campaign.create(title: 'test')
      c1.voice_numbers.new(@number1)
      c1.save

      c2 = Crowdring::Campaign.create(title: 'test2')
      c2.voice_numbers.new(@number1)
      
      c2.save.should be_false   
    end
  end

  describe 'campaign and ringer' do
    before(:each) do
      DataMapper.auto_migrate!
      @number1 = '+18001111111'
      @number2 = '+18002222222'
      @number3 = '+18003333333'
      @number4 = '+18004444444'
      @number5 = '+18005555555'
      @c = Crowdring::Campaign.create(title: 'test', voice_numbers: [{phone_number: @number2, description: 'num1'}], sms_number: @number3)
    end

    it 'should have many ringers' do
      r1 = Crowdring::Ringer.create(phone_number: @number1)
      r2 = Crowdring::Ringer.create(phone_number: @number2)
      @c.rings.create(ringer: r1)
      @c.rings.create(ringer: r2)

      @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number1))
      @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number2))
    end

    it 'should track the original date a ringer supported a campaign' do
      r = Crowdring::Ringer.create(phone_number: @number2)
      @c.voice_numbers.first.ring(r)

      @c.rings.first.created_at.to_date.should eq(Date.today)
    end

    it 'should track all of the times a ringer rings a campaign' do
      r = Crowdring::Ringer.create(phone_number: @number2)
      @c.voice_numbers.first.ring(r)

      @c.rings.count.should eq(1)
    end

    it 'should remove rings when a campaign is destroyed' do
      r = Crowdring::Ringer.create(phone_number: @number2)
      @c.voice_numbers.first.ring(r)
      @c.destroy

      Crowdring::Ring.all.should be_empty
      Crowdring::Ringer.all.count.should eq(1)
    end

    it 'should be able to provide the ringers of a certain assigned number' do
      @c.voice_numbers << {phone_number: @number3, description: 'num3'}
      @c.save
      r = Crowdring::Ringer.create(phone_number: @number4)
      r2 = Crowdring::Ringer.create(phone_number: @number5)
      @c.voice_numbers.first.ring(r)
      @c.voice_numbers.last.ring(r2)

      @c.ringers_from(@c.voice_numbers.first).should eq([r])
      @c.ringers_from(@c.voice_numbers.last).should eq([r2])
    end
  end

  describe 'campaign and asks' do
    include Rack::Test::Methods

    before(:each) do
      Crowdring::Server.service_handler.reset
      DataMapper.auto_migrate!
      @number1 = '+18001111111'
      @number2 = '+18002222222'
      @number3 = '+18003333333'
      @c = Crowdring::Campaign.create(title: 'test', voice_numbers: [{phone_number: @number2, description: 'num1'}], sms_number: @number3)
    end

    it 'should be able to add new ask after campaign creation' do
      params = {'ask_type' => 'text_ask', 'trigger_by' => 'user','campaign' => { 'message' => {'default_message' => 'hello'}}}
      post "/campaign/#{@c.id}/asks/create" ,params

      @c.asks.count.should eq(2)
    end
  end
end
