module Crowdring
  class AggregateCampaign
    include DataMapper::Resource

    property :name, String, required: true, unique: true, key: true

    has n, :campaigns, through: Resource, constraint: :skip

    def campaigns=(campaigns)
      campaigns = campaigns.map {|c| Campaign.get(c)} if campaigns.first.is_a?(Fixnum) || campaigns.first.is_a?(String)
      super campaigns
    end

    def ringer_count
      campaigns.reduce(0) {|sum, c| c.ringers.count + sum}
    end

    def campaign_summary
      return 'no campaigns' if campaigns.empty?
      full_summary = campaigns.map(&:title).join(', ')
      full_summary = full_summary[0..80] + '...' if full_summary.length > 80
      full_summary
    end
  end
end