module Crowdring
  module AssignedPhoneNumberFields
    def self.included(base)
      base.class_eval do
        include DataMapper::Resource

        property :id, DataMapper::Property::Serial
        property :phone_number, DataMapper::Property::String, key: true
        property :raw_number, DataMapper::Property::String
        validates_uniqueness_of :phone_number

        def phone_number=(number)
          self.raw_number = number
          super (Phonie::Phone.parse(number) || number).to_s
        end

        def self.from(number)
          norm_number = Phonie::Phone.parse(number).to_s
          self.first(phone_number: norm_number)
        end
      end
    end
  end

  class AssignedVoiceNumber
    include AssignedPhoneNumberFields
    include PhoneNumberFields

    property :type, Discriminator
    property :description, String, default: '[No description given]'

    belongs_to :campaign, required: false

    validates_with_method :phone_number, :valid_phone_number?

    def description=(text)
      super unless text.empty?
    end
  end

  class AssignedCampaignVoiceNumber < AssignedVoiceNumber
    validates_presence_of :campaign
    validates_length_of :description, max: 64
    
    after :create do
      tag
    end

    after :destroy do
      tag.destroy
    end

    def tag
      Tag.from_str("rang:#{id}")
    end


    def ring(ringer)
      ringer.tag(tag)
      campaign.ring(ringer)
    end
  end

  class AssignedUnsubscribeVoiceNumber < AssignedVoiceNumber
    def ring(ringer)
      ringer.unsubscribe
    end
  end

  class AssignedSMSNumber
    include AssignedPhoneNumberFields
    include PhoneNumberFields
    belongs_to :campaign

    def text(ringer, message)
      campaign.text(ringer, message)
    end
  end

  class AssignedPhoneNumber
    def self.from(type, number)
      case type
      when :voice
        AssignedVoiceNumber.from(number)
      when :sms
        AssignedSMSNumber.from(number)
      end
    end

    def self.handle(type, request)
      number = from(type, request.to)
      ringer = Ringer.from(request.from)
      ringer.subscribe

      case number
      when AssignedVoiceNumber
        number.ring(ringer)
        [{cmd: :ivr, text: ivr(number)}] if ivr?(number)
      when AssignedSMSNumber
        number.text(ringer, request.message)
      end
    end

    def self.ivr?(number)
      number.class == Crowdring::AssignedCampaignVoiceNumber && !number.campaign.ivrs.empty? 
    end

    def self.ivr(number)
      campaign = number.campaign
      campaign.ivrs.last
    end
  end
end