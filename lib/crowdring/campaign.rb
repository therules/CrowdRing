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
    has n, :texts, constraint: :destroy

    has n, :voice_numbers, 'AssignedCampaignVoiceNumber', constraint: :destroy
    has 1, :sms_number, 'AssignedSMSNumber', constraint: :destroy
    
    has n, :asks, through: Resource, constraint: :destroy

    validates_with_method :voice_numbers, :at_least_one_assigned_number?

    def initialize(opts)
      super opts
      asks << OfflineAsk.create
    end

    def sms_number=(number)
      number = AssignedSMSNumber.new(phone_number: number) if number.is_a? String
      super number
    end

    def ringers
      rings.all.ringer
    end

    def ring(ringer)
      return unless rings.create(ringer: ringer).saved?
      ask = asks.reverse.find {|ask| ask.handle?(:voice, ringer) }
      ask.respond(ringer, sms_number.raw_number) if ask
    end

    def text(ringer, message)
      text = texts.create(ringer: ringer, message: message)
      ask = asks.reverse.find {|ask| ask.handle?(:sms, ringer) }
      ask.text(ringer, text, sms_number.raw_number) if ask
    end

    def unique_rings
      ringers_to_rings = rings.all.reduce({}) do |res, ring|
        res.merge(res.key?(ring.ringer_id) ? {} : {ring.ringer_id => ring})
      end
      ringers_to_rings.values
    end

    def all_errors
      allerrors = [errors]
      allerrors << voice_numbers.map {|n| n.errors}
      allerrors << sms_number.errors if sms_number
      allerrors.flatten
    end

    def slug
      title.gsub(/\s/, '_').gsub(/[^a-zA-Z_]/, '').downcase
    end

    private

    def at_least_one_assigned_number?
      if @voice_numbers && !@voice_numbers.empty?
        true
      else
        [false, 'Must assign at least one number']
      end
    end
  end
end