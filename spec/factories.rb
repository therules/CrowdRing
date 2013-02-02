FactoryGirl.define do
  factory :campaign, :class => "Crowdring::Campaign" do

    sequence(:title) {|n| "Campaign #{n}"}
  # t.voice_numbers ['+18001111111']
  # t.sms_number '+18002222222'
  end

  factory :ringer, :class => "Crowdring::Ringer" do
    sequence(:phone_number){|n| "+1212111111#{n}"}

  end

  factory :invalid_ringer, class: "Crowdring::Ringer" do
    phone_number 'invalid'
  end

  factory :area_code, class: "Crowdring::Tag" do
    group "area code"
    value "212"
  end

  factory :country, class: "Crowdring::Tag" do
    group "country"
    value "united states"
  end
end

