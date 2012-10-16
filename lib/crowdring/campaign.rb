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
    has n, :assigned_phone_numbers, constraint: :destroy
    has n, :asks, through: Resource, constraint: :destroy

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

    def ring(ringer, number_rang)
      ring = rings.create(ringer: ringer, number_rang: number_rang)
      ask = asks.reverse.find {|ask| ask.handle?(ring) }
      ask.respond(ring) if ask
    end

    def unique_rings
      ringers_to_rings = rings.all.reduce({}) do |res, ring|
        res.merge(res.key?(ring.ringer_id) ? {} : {ring.ringer_id => ring})
      end
      ringers_to_rings.values
    end

    def assigned_phone_numbers=(numbers)
      if !numbers.empty? and numbers.first.is_a? String
        numbers = numbers.map {|n| AssignedPhoneNumber.new(phone_number: n) }
      end

      super numbers
    end

    def all_errors
      allerrors = [errors]
      allerrors += assigned_phone_numbers ? assigned_phone_numbers.map(&:errors) : []
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