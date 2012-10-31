module Crowdring
  module AssignedPhoneNumberFields
    def self.included(base)
      base.class_eval do
        include DataMapper::Resource

        property :id, DataMapper::Property::Serial
        property :phone_number, DataMapper::Property::String

        belongs_to :campaign

        validates_uniqueness_of :phone_number

        def self.from(number)
          norm_number = Phoner::Phone.parse(number).to_s
          self.first(phone_number: norm_number)
        end

      end
    end
  end

  class AssignedVoiceNumber
    include AssignedPhoneNumberFields
    include PhoneNumberFields

    property :description, String, required: true, length: 0..64,
      messages: { presence: 'Non-empty description required',
                  length: 'Description must be fewer than 64 letters in length' }
                  
    validates_with_method :phone_number, :valid_phone_number?

    def ring(ringer)
      campaign.ring(ringer)
    end
  end

  class AssignedSMSNumber
    include AssignedPhoneNumberFields
    include PhoneNumberFields

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

      case number
      when AssignedVoiceNumber
        number.ring(ringer)
      when AssignedSMSNumber
        number.text(ringer, request.message)
      end
    end
  end
end