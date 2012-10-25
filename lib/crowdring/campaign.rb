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

    has n, :voice_numbers, 'AssignedVoiceNumber', constraint: :destroy
    has 1, :sms_number, 'AssignedSMSNumber', constraint: :destroy
    
    has n, :asks, through: Resource, constraint: :destroy
    
    def initialize(opts)
      message = opts.delete('message') || opts.delete(:message)
      super opts
      ask = Ask.create_double_opt_in(message)
      asks << ask
      asks << ask.triggered_ask
    end

    def sms_number=(number)
      number = {phone_number: number} if number.is_a? String
      super number
    end

    def ringers
      rings.all.ringer
    end

    def response_numbers
      ResponseNumbers.new(voice_number: voice_numbers.first.phone_number, sms_number: sms_number.phone_number)
    end

    def ring(ringer)
      return unless rings.create(ringer: ringer).saved?
      ask = asks.reverse.find {|ask| ask.handle?(ringer) }
      ask.respond(ringer, response_numbers) if ask
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