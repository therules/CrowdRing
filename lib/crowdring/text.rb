module Crowdring
  class Text
    include DataMapper::Resource
    include PhoneNumberFields

    property :id, Serial
    property :created_at, DateTime
    property :message, String, length: 160

    belongs_to :campaign
    belongs_to :ringer

    def phone_number
      ringer.phone_number
    end
  end
end
