module Crowdring
  class Ask
    include DataMapper::Resource

    property :id, Serial
    property :type, Discriminator
    property :created_at, DateTime

    belongs_to :message, required: false
    belongs_to :triggered_ask, 'Ask', required: false

    before :create do
      message.save if message
    end

    def self.create_double_opt_in(message)
      offline_ask = OfflineAsk.create
      join_ask = JoinAsk.create(message: message)
      offline_ask.triggered_ask = join_ask
      offline_ask
    end

    def recipient_tag
      Tag.from_str("#{id}:recipient")
    end

    def respondent_tag
      Tag.from_str("#{id}:respondent")
    end

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
    def handle?(ring)
      true
    end
  end

  class JoinAsk < Ask
    def handle?(ring)
      ring.ringer.tags.include? recipient_tag
    end
  end
end
