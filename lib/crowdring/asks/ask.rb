module Crowdring
  class Ask
    include DataMapper::Resource

    property :id, Serial
    property :title, String, unique: true, required: true, length: 0..100
    property :type, Discriminator
    property :created_at, DateTime
    property :prompt, String, length: 250, lazy: false, required: false

    belongs_to :message, required: false
    belongs_to :triggered_ask, 'Ask', required: false

    before :create do
      message.save if message
    end

    after :create do
      recipient_tag
      respondent_tag
    end

    after :destroy do
      recipient_tag.destroy
      respondent_tag.destroy
    end
    
    def handle?(type, ringer)
      ringer.tagged?(recipient_tag)
    end

    def recipient_tag
      Tag.from_str("ask_recipient:#{id}")
    end

    def respondent_tag
      Tag.from_str("ask_respondent:#{id}")
    end

    def respond(ringer, sms_number)
      ringer.tag(respondent_tag)

      triggered_ask.trigger_for(ringer, sms_number) if triggered_ask

      [{cmd: :reject}]
    end

    def potential_recipients(ringers)
      ringers.reject {|r| r.tagged?(recipient_tag) }
    end

    def recipients(ringers=Ringer.subscribed)
      ringers.select {|r| r.tagged?(recipient_tag)}
    end

    def respondents(ringers=Ringer.subscribed)
      ringers.select {|r| r.tagged?(respondent_tag)}
    end

    def trigger_for(ringer, sms_number)
      ringer.tag(recipient_tag)
      message.send_message(to: ringer, from: sms_number) if message
    end

    def trigger(ringers, sms_number)
      ringers.each {|ringer| trigger_for(ringer, sms_number) }
    end

    def initial_price_estimate(ringers=Ringer.all, sms_number)
      return 0.0 if message.nil?

      smss = ringers.map do |ringer|
        text = message.for(ringer, sms_number)
        text && OutgoingSMS.new(from: sms_number, to: ringer.phone_number, text: text)
      end

      PriceEstimate.new(smss.compact)
    end

    def all_errors
      allerrors = [errors]
      allerrors << message.errors unless message.nil?
      allerrors.flatten
    end
  end
end
