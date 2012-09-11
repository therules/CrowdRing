module Crowdring
  class Supporter
    include DataMapper::Resource

    property :id,           Serial
    property :phone_number, String

    belongs_to :campaign

    after :save do |s|
      Pusher[s.campaign.phone_number[1..-1]].trigger('new', { number: s.phone_number, count: s.campaign.supporters.size })
    end
  end
end