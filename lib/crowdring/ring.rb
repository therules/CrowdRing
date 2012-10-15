module Crowdring
  class Ring
    include DataMapper::Resource
    include PhoneNumberFields

    property :id, Serial
    property :created_at,   DateTime

    belongs_to :campaign
    belongs_to :ringer
    belongs_to :number_rang, 'AssignedPhoneNumber'

    def phone_number
      ringer.phone_number
    end
  end
end