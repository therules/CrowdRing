module Crowdring
  module AssignedPhoneNumberFields
    def self.included(base)
      base.class_eval do
        include DataMapper::Resource

        property :id, DataMapper::Property::Serial
        property :phone_number, DataMapper::Property::String

        belongs_to :campaign

        validates_with_method :phone_number, :valid_phone_number?
        validates_uniqueness_of :phone_number

        def self.from(number)
          norm_number = Phoner::Phone.parse(number).to_s
          self.first(phone_number: norm_number)
        end

        def ring(ringer)
          campaign.ring(ringer)
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
  end

  class AssignedSMSNumber
    include AssignedPhoneNumberFields
    include PhoneNumberFields
  end
end