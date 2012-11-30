module Crowdring
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