FactoryGirl.define do
  factory :campaign, :class => "Crowdring::Campaign" do

    sequence(:title) {|n| "Campaign #{n}"}
    goal 20
    association :voice_number
    association :sms_number
    association :asks
  end

  factory :voice_number, :class => "Crowdring::AssignedVoiceNumber" do
    sequence(:phone_number){|n| "+1800111111#{n}"}
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

