module Crowdring
  class CampaignMembership
    include DataMapper::Resource
    include PhoneNumberFields

    timestamps :at
    property :count, Integer, default: 0

    belongs_to :campaign, 'Campaign', key: true
    belongs_to :supporter, 'Supporter', key: true

    after :create do |m|
      data = {  number: m.supporter.pretty_phone_number,
                supporter_count: m.campaign.supporters.count,
                new_supporter_count: m.campaign.new_memberships.count }
      begin
        Pusher[m.campaign.id].trigger('new', data) 
      rescue SocketError
        p "SocketError: Failed to send message to Pusher"
      end
    end

    private 

    def support_date
      created_at.strftime('%F')
    end

    def phone_number
      supporter.phone_number
    end

  end
end
