module Crowdring
  class Ringer
    include DataMapper::Resource
    include PhoneNumberFields

    property :id,           Serial
    property :phone_number, String, unique: true
    property :created_at,   DateTime

    has n, :campaign_memberships, constraint: :destroy
    has n, :campaigns, through:  :campaign_memberships

    has n, :tags, through: Resource, constraint: :skip
    
    validates_with_method :phone_number, :valid_phone_number?

    after :create, :add_tags

    def add_tags
      tags << Tag.from_str('area code:' + area_code)
      save
    end
  end
end