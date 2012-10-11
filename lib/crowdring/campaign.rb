module Crowdring
  class Campaign
    include DataMapper::Resource

    property :id,           Serial
    property :title,        String, required: true, length: 0..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime
    property :created_at,   DateTime

    has n, :assigned_phone_numbers, constraint: :destroy
    has n, :memberships, 'CampaignMembership', constraint: :destroy
    has n, :ringers, through: :memberships
    belongs_to :introductory_response

    before :create do
      introductory_response.save
    end 

    before :update do
      introductory_response.save
    end

    def assigned_phone_numbers=(numbers)
      if !numbers.empty? and numbers.first.is_a? String
        numbers = numbers.map {|n| AssignedPhoneNumber.new(phone_number: n) }
      end

      super numbers
    end

    def all_errors
      allerrors = [errors]
      allerrors += assigned_phone_numbers ? assigned_phone_numbers.map(&:errors) : []
      allerrors += introductory_response ? [introductory_response.errors] : []
      allerrors
    end

    def join(ringer)
      membership = memberships.first_or_create(ringer: ringer)
      membership.update(count: membership.count+1)
    end

    def new_memberships
      if most_recent_broadcast.nil?
        memberships 
      else
        memberships.select { |s| s.created_at > most_recent_broadcast }
      end
    end

    def ring_count
      memberships.reduce(0) {|count, m| count + m.count }
    end

    def slug
      title.gsub(/\s/, '_').gsub(/[^a-zA-Z_]/, '').downcase
    end
  end
end