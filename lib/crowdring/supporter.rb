module Crowdring
  class Supporter
    include DataMapper::Resource

    property :id,           Serial
    property :phone_number, String
    property :created_at,   DateTime

    belongs_to :campaign

    after :save do |s|
      Pusher[s.campaign.phone_number[1..-1]].trigger('new', { number: s.pretty_phone_number, count: s.campaign.supporters.size })
    end

    def pretty_phone_number
      number = Phoner::Phone.parse phone_number
      number.format("+ %c (%a) %n") + " [" + Phoner::Country.find_by_country_code(number.country_code).char_3_code + "]"
    end
  end
end