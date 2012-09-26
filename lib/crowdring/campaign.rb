module Crowdring
  class Campaign
    include DataMapper::Resource
    include PhoneNumberFields

    property :phone_number, String, key: true
    property :title,        String, required: true, length: 0..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime

    validates_with_method :phone_number, :valid_phone_number?

    has n, :supporters, constraint: :destroy
    
    def introductory_message
      "Thanks for supporting #{title}! Have a lovely day!"
    end

    def new_supporters
      if most_recent_broadcast.nil?
        supporters
      else
        supporters.select { |s| s.created_at > most_recent_broadcast }
      end
    end
  end
end