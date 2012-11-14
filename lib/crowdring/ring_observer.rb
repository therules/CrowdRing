module Crowdring
  class RingObserver
    include DataMapper::Observer

    observe Ring

    after :create do |r|
      if r.campaign.rings.all(ringer: r).count == 1
        RingObserver.statsd_increment("members_joined", r.campaign.slug) 
      else
        RingObserver.statsd_increment("members_responded", r.campaign.slug)
      end
      RingObserver.push_notify(r)
    end

    def self.statsd_increment(stat, slug=nil)
      Crowdring.statsd.increment "#{stat}.count"
      Crowdring.statsd.increment "campaigns.#{slug}.#{stat}.count" if slug
    end

    def self.push_notify(m)
      data = {  number: m.ringer.pretty_phone_number,
          ringer_count: m.campaign.ringers.count,
          ring_count: m.campaign.rings.count,
          goal: m.campaign.goal }

      begin
        Pusher[m.campaign.id].trigger('new', data) 
      rescue SocketError
        p "SocketError: Failed to send message to Pusher"
      end
    end
  end
end