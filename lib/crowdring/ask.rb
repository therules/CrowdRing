module Crowdring
  class Ask
    include DataMapper::Resource

    property :id, Serial
    property :type, Discriminator

    belongs_to :message, required: false
    belongs_to :triggered_ask, 'Ask', required: false

    def respond(ring)
      ring.ringer.tags << respondent_tag
      ring.ringer.save

      triggered_ask.trigger_for(ring) if triggered_ask
    end

    def recipients(ringers)
      ringers.select {|r| r.tags.include?(recipient_tag)}
    end

    def respondents(ringers)
      ringers.select {|r| r.tags.include?(respondent_tag)}
    end

    def trigger_for(ring)
      ring.ringer.tags << recipient_tag
      ring.ringer.save

      message.send_message(to: ring.ringer, from: ring.number_rang.phone_number) if message
    end
  end


  class OfflineAsk < Ask
    def initialize(opts={doubletap: true})
      self.triggered_ask = JoinAsk.create if opts[:doubletap]
    end

    def respondent_tag
      Tag.from_str("#{id}:supporter")
    end
  end

  class JoinAsk < Ask
    def recipient_tag
      Tag.from_str("#{id}:supporter")
    end

    def respondent_tag
      Tag.from_str("#{id}:subscriber")
    end
    
  end
end
