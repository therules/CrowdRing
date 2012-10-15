module Crowdring
	class CampaignStats
		@@stats = {}

		def initialize(campaign)
			@campaign = campaign
		end

		def self.calculate(campaign, stat)
			@@stats[stat].new(campaign).calculate
		end

		def self.register(id)
			@@stats[id] = self
		end
	end

	class MemberTotal < CampaignStats
		def calculate
			unique_rings = @campaign.unique_rings
      datapoints = unique_rings.each_with_index.map {|ring, index| [ring.created_at.strftime('%Q').to_i, index + 1] } 
      datapoints.unshift([@campaign.created_at.strftime('%Q').to_i, 0])
      datapoints << [DateTime.now.strftime('%Q').to_i, unique_rings.size]
    end

    register :member_total
  end

  class NewMembersPerDay < CampaignStats
  	def calculate
    	datapoints = CampaignStats.calculate(@campaign, :member_total)
      datapoints.each_cons(2).map do |dps|
	      thisPoint = dps.first
	      nextPoint = dps.last
	      [(thisPoint[0] + nextPoint[0])/2, ((nextPoint[1] - thisPoint[1]).to_f / (nextPoint[0] - thisPoint[0]).to_f) * 1000*60*60*24]
	    end
	  end

	  register :new_members_per_day
	end 
end