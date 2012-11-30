module Crowdring
  class Ask
    include DataMapper::Resource

    property :id, Serial
    property :title, String
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
  end


  class OfflineAsk < Ask
    def title
      'Offline Ask'
    end

    def handle?(type, ringer)
      type == :voice
    end

    def self.typesym
      :offline_ask
    end
  end

  class SendSMSAsk < Ask
    def handle?(type, ringer)
      false
    end

    def self.typesym
      :send_sms_ask
    end

    def self.readable_name
      'Send a text message'
    end
  end

  class JoinAsk < Ask
    def handle?(type, ringer)
      type == :voice && super(type, ringer)
    end

    def self.typesym
      :join_ask
    end

  end

  class TextAsk < Ask
    has n, :texts, through: Resource

    def handle?(type, ringer)
      type == :sms && super(type, ringer)
    end

    def text(ringer, text, sms_number)
      texts << text
      self.save

      respond(ringer, sms_number)
    end

    def self.typesym
      :text_ask
    end

    def self.readable_name
      'Recieve a text message'
    end
  end

  class VoicemailAsk < Ask
    property :prompt, String, length: 250

    has n, :voicemails, through: Resource, constraint: :destroy

    def handle?(type, ringer)
      type == :voice && super(type, ringer)
    end

    def respond(ringer, sms_number)
      voicemail = voicemails.create(ringer: ringer)
      super(ringer, sms_number)
      [{cmd: :record, prompt: prompt, voicemail: voicemail}]
    end

    def self.typesym
      :voicemail_ask
    end

    def self.readable_name
      'Receive a voice message'
    end

  end
end
