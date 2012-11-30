module Crowdring
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
end