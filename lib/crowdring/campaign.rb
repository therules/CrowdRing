module Crowdring
  class Campaign
    include DataMapper::Resource

    property :phone_number, String, key: true
    property :title,        String, required: true, length: 0..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be fewer than 64 letters in length' }
    property :most_recent_broadcast, DateTime

    validates_with_method :phone_number, :valid_phone_number?

    has n, :supporters, constraint: :destroy
    
    def pretty_phone_number
      number = Phoner::Phone.parse phone_number
      number.format "+%c (%a) %n" + " [" + Phoner::Country.find_by_country_code(number.country_code).char_3_code + "]"
    end

    def introductory_message
      "Thanks for supporting #{title}! Have a lovely day!"
    end

    def new_supporters
      supporters.select { |s| s.created_at > most_recent_broadcast }
    end

    private

    def valid_phone_number?
      if Phoner::Phone.valid? @phone_number
        true
      else
        [false, 'Phone number does not appear to be valid']
      end
    end

  end
end