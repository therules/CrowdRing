module Crowdring
  class CampaignMembershipObserver
    include DataMapper::Observer

    observe CampaignMembership

    after :create do |m|
      CampaignMembershipObserver.push_notify(m)
      CampaignMembershipObserver.statsd_increment("members_joined", m.campaign.slug)
    end

    after :update do |m|
      CampaignMembershipObserver.statsd_increment("members_responded", m.campaign.slug)
    end
      
    def self.statsd_increment(stat, slug=nil)
      Crowdring.statsd.increment "#{stat}.count"
      Crowdring.statsd.increment "campaigns.#{slug}.#{stat}.count" if slug
    end

    def self.push_notify(m)
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