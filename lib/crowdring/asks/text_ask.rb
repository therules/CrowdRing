module Crowdring
  class TextAsk < Ask
    has n, :texts, through: Resource, constraint: :destroy
    validates_presence_of :message
    def handle?(type, ringer)
      type == :sms && super(type, ringer)
    end

    def text(ringer, text, sms_number)
      email = find_email(text.message)
      if email
        ringer.email = email.to_s 
        ringer.save
      end
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

    def find_email(message)
      pattern = Regexp.new(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)
      email = pattern.match(message)
    end
  end
end