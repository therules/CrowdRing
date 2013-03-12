describe Crowdring::Ringer do
  let(:ringer){ create(:ringer) }

  before(:each) do
    DataMapper.auto_migrate!
  end

  it { should validate_presence_of :phone_number}
  it { should have_many(:tags)}
  it { should have_many(:ringer_taggings)}
  it { should have_many(:rings)}
  it { should validate_uniqueness_of :phone_number}

  context "Invalid ringer phone_number" do
    let(:invalid){ build(:invalid_ringer) }
    it { invalid.should_not be_valid}
  end

  context "New ringer has tag of area code" do
    let(:area_code){ build(:area_code)}
    let(:country){ build(:country)}

    subject{ Crowdring::Ringer.create(phone_number: '+12121111111')}

    its(:tags){ should include area_code }
    its(:tags){ should include country }
  end
end
