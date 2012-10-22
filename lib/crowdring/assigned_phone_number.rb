module Crowdring
  class AssignedPhoneNumber
    include DataMapper::Resource
    include PhoneNumberFields

    property :id, Serial
    property :phone_number, String
    property :type, Discriminator

    def self.from_number(number)
      self.first(phone_number: number)
    end

    def ring(ringer)
      campaign.ring(ringer)
    end

    validates_with_method :phone_number, :valid_phone_number?
  end

  class AssignedSMSNumber < AssignedPhoneNumber
    has 1, :campaign, child_key: [:sms_number_id], constraint: :set_nil
    validates_uniqueness_of :phone_number
  end

  class AssignedVoiceNumber < AssignedPhoneNumber
    has 1, :campaign, child_key: [:voice_number_id], constraint: :set_nil
    validates_uniqueness_of :phone_number
  end
end