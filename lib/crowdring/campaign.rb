module Crowdring
  class Campaign
    include DataMapper::Resource

    property :id,           Serial
    property :title,        String, required: true, length: 0..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime
    property :introductory_message, String, required: true, length: 0..160,
      messages: { presence: 'Non-empty introductory message required',
                    length: 'Introductory message must be fewer than 160 letters in length' }

    has n, :assigned_phone_numbers, constraint: :destroy
    has n, :memberships, 'CampaignMembership', constraint: :destroy
    has n, :supporters, through: :memberships

    def assign_phone_numbers(numbers)
      numbers && numbers.inject(true) do |res, n|
        begin
          assigned_phone_numbers.create(phone_number: n).saved? && res 
        rescue DataObjects::IntegrityError
          false
        end
      end
    end

    def join(supporter)
      membership = memberships.first_or_create(supporter: supporter)
      membership.update(count: membership.count+1)
    end

    def new_memberships
      if most_recent_broadcast.nil?
        memberships 
      else
        memberships.select { |s| s.created_at > most_recent_broadcast }
      end
    end
  end
end