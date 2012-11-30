module Crowdring
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
end