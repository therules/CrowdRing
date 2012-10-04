module Crowdring
  class CampaignMembershipObserver
    include DataMapper::Observer

    observe CampaignMembership

    after :create do |m|
      data = {  number: m.ringer.pretty_phone_number,
                ringer_count: m.campaign.memberships.count,
                new_ringer_count: m.campaign.new_memberships.count }
      begin
        Pusher[m.campaign.id].trigger('new', data) 
      rescue SocketError
        p "SocketError: Failed to send message to Pusher"
      end
    end
  end
end