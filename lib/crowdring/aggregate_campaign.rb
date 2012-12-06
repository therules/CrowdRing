module Crowdring
  class AggregateCampaign
    include DataMapper::Resource

    property :name, String, required: true, key: true

    has n, :campaigns, through: Resource, constraint: :skip

    def campaigns=(campaigns)
      campaigns = campaigns.map {|c| Campaign.get(c)} if campaigns.first.is_a? Fixnum
      super campaigns
    end

    def ringer_count
      campaigns.reduce(0) {|sum, c| c.ringers.count + sum}
    end
  end
end