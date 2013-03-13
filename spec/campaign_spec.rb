describe Crowdring::Campaign do
  it { should validate_presence_of :goal }
  it { should have_many :rings }
  it { should have_many :asks }
  it { should have_many :ivrs }
  it { should have_many :aggregate_campaigns }
  it { should have_many :voice_numbers }
  it { should have_one :sms_number}

  let(:voice_number) { [{phone_number: '+18001111111', description: 'numer1'}]}
  let(:sms_number){ '+18002222222'}
  let(:goal) { 100 }
  let(:campaign) { Crowdring::Campaign.create(title: 'test', voice_numbers: voice_number, sms_number: sms_number, goal: goal)}
  before { DataMapper.auto_migrate! }
  context 'campaign creation' do

    context 'Create with valid parameters' do
      subject { campaign }
      its(:title) { should == 'test'}
      its(:voice_numbers){ should == Crowdring::AssignedVoiceNumber.all }
      its(:sms_number) { should == Crowdring::AssignedSMSNumber.first }
    end

    context 'Create with invalid parameters' do
      subject { Crowdring::Campaign.create()}
      its(:title) { should be_nil }
      its(:valid?) { should be_false }
    end

    context 'Destroy a campaign' do
      subject { campaign.destroy }
      it { should be_true }

      subject { Crowdring::AssignedCampaignVoiceNumber.all }
      it { should be_empty }

      subject { Crowdring::AssignedSMSNumber.all }
      it { should be_empty }
    end

    context 'Offline Ask creation' do
      subject { campaign.asks.first }
      its(:title) { should include('Offline Ask') }
      its(:class) { should == Crowdring::OfflineAsk }
    end
  end
  context 'Campaign and Ringer' do
    let(:ana) { build(:ringer) }
    let(:jack) { build(:ringer)}

    before do
      subject { campaign }
      campaign.rings.stub_chain(:create, :saved?).and_return(true)
    end

    subject { campaign.ring(ana) }
    it { should be_true }
  end
  # describe 'campaign and ringer' do
  #   before(:each) do
  #     DataMapper.auto_migrate!
  #     @number1 = '+18001111111'
  #     @number2 = '+18002222222'
  #     @number3 = '+18003333333'
  #     @number4 = '+18004444444'
  #     @number5 = '+18005555555'
  #     @c = Crowdring::Campaign.create(title: 'test', voice_numbers: [{phone_number: @number2, description: 'num1'}], sms_number: @number3)
  #   end

  #   it 'should have many ringers' do
  #     r1 = Crowdring::Ringer.create(phone_number: @number1)
  #     r2 = Crowdring::Ringer.create(phone_number: @number2)
  #     @c.rings.create(ringer: r1)
  #     @c.rings.create(ringer: r2)

  #     @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number1))
  #     @c.ringers.should include(Crowdring::Ringer.first(phone_number: @number2))
  #   end

  #   it 'should track the original date a ringer supported a campaign' do
  #     r = Crowdring::Ringer.create(phone_number: @number2)
  #     @c.voice_numbers.first.ring(r)

  #     @c.rings.first.created_at.to_date.should eq(Date.today)
  #   end

  #   it 'should track all of the times a ringer rings a campaign' do
  #     r = Crowdring::Ringer.create(phone_number: @number2)
  #     @c.voice_numbers.first.ring(r)

  #     @c.rings.count.should eq(1)
  #   end

  #   it 'should remove rings when a campaign is destroyed' do
  #     r = Crowdring::Ringer.create(phone_number: @number2)
  #     @c.voice_numbers.first.ring(r)
  #     @c.destroy

  #     Crowdring::Ring.all.should be_empty
  #     Crowdring::Ringer.all.count.should eq(1)
  #   end

  #   it 'should be able to provide the ringers of a certain assigned number' do
  #     @c.voice_numbers << {phone_number: @number3, description: 'num3'}
  #     @c.save
  #     r = Crowdring::Ringer.create(phone_number: @number4)
  #     r2 = Crowdring::Ringer.create(phone_number: @number5)
  #     @c.voice_numbers.first.ring(r)
  #     @c.voice_numbers.last.ring(r2)

  #     @c.ringers_from(@c.voice_numbers.first).should eq([r])
  #     @c.ringers_from(@c.voice_numbers.last).should eq([r2])
  #   end
  # end

end
