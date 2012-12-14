module Crowdring
  class Campaign
    include DataMapper::Resource

    property :id,           Serial
    property :title,        String, required: true, length: 0..64, unique: true,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime
    property :created_at,   DateTime
    property :goal, Integer, default: 777

    property :ringer_count, Integer, default: 0

    has n, :rings, constraint: :destroy

    has n, :asks, through: Resource, constraint: :destroy

    has n, :voice_numbers, 'AssignedCampaignVoiceNumber', constraint: :destroy
    has 1, :sms_number, 'AssignedSMSNumber', constraint: :destroy

    has n, :aggregate_campaigns, through: Resource, constraint: :skip
    

    validates_with_method :voice_numbers, :at_least_one_assigned_number?

    before :create do
      asks << OfflineAsk.create(title: "Offline Ask - #{title}")
    end

    after :create do
      tag
    end

    after :destroy do
      tag.destroy
    end

    def sms_number=(number)
      number = AssignedSMSNumber.new(phone_number: number) if number.is_a? String
      super number
    end

    def country
      sms_number.country.name
    end

    def ringers
      rings.all.ringer
    end

    def ringers_from(assigned_number)
      ringers.select {|r| r.tagged?(assigned_number.tag) }
    end

    def tag
      Tag.from_str("campaign:#{id}")
    end

    def ring(ringer)
      update! ringer_count: ringer_count + 1 unless ringers.include?(ringer)
      return unless rings.create(ringer: ringer).saved?
      ringer.tag(tag)
      ask = asks.reverse.find {|ask| ask.handle?(:voice, ringer) }
      ask.respond(ringer, sms_number.raw_number) if ask
    end

    def text(ringer, message)
      text = Text.create(ringer: ringer, message: message)
      ask = asks.reverse.find {|ask| ask.handle?(:sms, ringer) }
      ask.text(ringer, text, sms_number.raw_number) if ask
    end

    def unique_rings(assigned_number=nil)
      ringers_to_rings = rings.all.reduce({}) do |res, ring|
        res.merge(res.key?(ring.ringer_id) ? {} : {ring.ringer_id => ring})
      end
      if assigned_number
        (ringers_to_rings.select {|_,ring| ring.ringer.tagged?(assigned_number.tag) }).values
      else
        ringers_to_rings.values
      end
    end

    def triggered_ask?(ask)
      !(asks.find{|n| n.triggered_ask && n.triggered_ask == ask}.nil? && ask != asks.first)
    end

    def all_errors
      allerrors = [errors]
      allerrors << voice_numbers.map(&:errors)
      allerrors << sms_number.errors if sms_number
      allerrors << asks.map(&:errors)
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