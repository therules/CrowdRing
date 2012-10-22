module Crowdring
  class Campaign
    include DataMapper::Resource

    property :id,           Serial
    property :title,        String, required: true, length: 0..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime
    property :created_at,   DateTime

    has n, :rings, constraint: :destroy

    belongs_to :voice_number, 'AssignedPhoneNumber', required: false
    belongs_to :sms_number, 'AssignedPhoneNumber', required: false
    
    has n, :asks, through: Resource, constraint: :destroy

    before :create do
      voice_number.save if voice_number
      sms_number.save if sms_number
    end

    after :destroy do
      voice_number.destroy if voice_number
      sms_number.destroy if sms_number
    end

    def initialize(opts)
      message = opts.delete('message') || opts.delete(:message)
      super opts
      ask = Ask.create_double_opt_in(message)
      asks << ask
      asks << ask.triggered_ask
    end

    def ringers
      rings.all.ringer
    end

    def response_numbers
      ResponseNumbers.new(voice_number: voice_number.phone_number, sms_number: sms_number.phone_number)
    end

    def ring(ringer)
      r = rings.create(ringer: ringer)
      ask = asks.reverse.find {|ask| ask.handle?(ringer) }
      ask.respond(ringer, response_numbers) if ask
    end

    def unique_rings
      ringers_to_rings = rings.all.reduce({}) do |res, ring|
        res.merge(res.key?(ring.ringer_id) ? {} : {ring.ringer_id => ring})
      end
      ringers_to_rings.values
    end

    def voice_number=(number)
      self.voice_number.destroy if self.voice_number
      if number.is_a? String
        self.voice_number = AssignedVoiceNumber.new(phone_number: number)
      else
        super number
      end
    end

    def sms_number=(number)
      self.sms_number.destroy if self.sms_number
      if number.is_a? String
        self.sms_number = AssignedSMSNumber.new(phone_number: number)
      else
        super number
      end
    end


    def all_errors
      allerrors = [errors]
      allerrors << voice_number.errors if voice_number
      allerrors << sms_number.errors if sms_number
      allerrors
    end

    def new_rings
      if most_recent_broadcast.nil?
        rings
      else
        rings.select { |r| r.created_at > most_recent_broadcast }
      end
    end

    def slug
      title.gsub(/\s/, '_').gsub(/[^a-zA-Z_]/, '').downcase
    end
  end
end