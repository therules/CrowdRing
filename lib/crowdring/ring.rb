module Crowdring
  class Ring
    include DataMapper::Resource
    include PhoneNumberFields

    property :id, Serial
    property :created_at,   DateTime

    belongs_to :campaign
    belongs_to :ringer

    validates_with_method :ringer, :nonredundant_ring?

    def nonredundant_ring?
      five_seconds_ago = Time.now - 5
      not Ring.first(ringer: @ringer, :created_at.gt => five_seconds_ago)
    end

    def phone_number
      ringer.phone_number
    end

    def campaign_support
      campaign.title
    end

    def email
      ringer.email
    end
  end
end