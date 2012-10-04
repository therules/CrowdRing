module Crowdring
  class CampaignMembership
    include DataMapper::Resource
    include PhoneNumberFields

    timestamps :at
    property :count, Integer, default: 0

    belongs_to :campaign, 'Campaign', key: true
    belongs_to :ringer, 'Ringer', key: true

    private 

    def support_date
      created_at.strftime('%F')
    end

    def phone_number
      ringer.phone_number
    end

  end
end
