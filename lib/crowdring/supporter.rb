module Crowdring
  class Supporter
    include DataMapper::Resource
    include PhoneNumberFields

    property :id,           Serial
    property :phone_number, String, unique: true
    property :created_at,   DateTime

    has n, :campaign_memberships, constraint: :destroy
    has n, :campaigns, :through => :campaign_memberships

    validates_with_method :phone_number, :valid_phone_number?
  end
end