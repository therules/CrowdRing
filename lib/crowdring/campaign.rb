module Crowdring
  class Campaign
    include DataMapper::Resource

    property :phone_number, String, key: true
    property :title,        String

    has n, :supporters, constraint: :destroy

  end
end