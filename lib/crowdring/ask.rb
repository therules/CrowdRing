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

    def handle?(type, ringer)
      ringer.tags.include? recipient_tag
    end

    def recipient_tag
      Tag.from_str("#{id}:recipient")
    end

    def respondent_tag
      Tag.from_str("#{id}:respondent")
    end

    def respond(ringer, response_numbers)
      ringer.tags << respondent_tag
      ringer.save

      triggered_ask.trigger_for(ringer, response_numbers) if triggered_ask
    end

    def recipients(ringers=Ringer.all)
      ringers.select {|r| r.tags.include?(recipient_tag)}
    end

    def respondents(ringers=Ringer.all)
      ringers.select {|r| r.tags.include?(respondent_tag)}
    end

    def trigger_for(ringer, response_numbers)
      ringer.tags << recipient_tag
      ringer.save

      message.send_message(to: ringer, from: response_numbers.sms_number) if message
    end

    def trigger(ringers, response_numbers)
      ringers.each {|ringer| trigger_for(ringer, response_numbers) }
    end
  end


  class OfflineAsk < Ask
    def handle?(type, ringer)
      type == :voice
    end

    def typesym
      :offline_ask
    end
  end

  class JoinAsk < Ask
    def handle?(type, ringer)
      type == :voice && super(type, ringer)
    end

    def typesym
      :join_ask
    end
  end

  class TextAsk < Ask
    has n, :texts, through: Resource

    def handle?(type, ringer)
      type == :sms && super(type, ringer)
    end

    def text(ringer, text, response_numbers)
      texts << text
      self.save

      respond(ringer, response_numbers)
    end

    def typesym
      :text_ask
    end
  end
end
