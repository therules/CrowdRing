module Crowdring
  class AssignedPhoneNumber
    include DataMapper::Resource
    include PhoneNumberFields

    property :id, Serial
    property :phone_number, String
    property :type, Discriminator

    belongs_to :campaign

    def self.get(number)
      self.first(phone_number: number)
    end

    def ring(ringer)
      campaign.ring(ringer)
    end

    validates_with_method :phone_number, :valid_phone_number?
  end

  class AssignedSMSNumber < AssignedPhoneNumber
    validates_uniqueness_of :phone_number
  end

  class AssignedVoiceNumber < AssignedPhoneNumber
    validates_uniqueness_of :phone_number
  end
end