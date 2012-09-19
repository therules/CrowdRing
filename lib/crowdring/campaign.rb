module Crowdring
  class Campaign
    include DataMapper::Resource

    property :phone_number, String, key: true
    property :title,        String, required: true, length: 1..64,
      messages: { presence: 'Non-empty title required',
                  length: 'Title must be between 1-64 letters in length' }

    validates_with_method :phone_number, :valid_phone_number?

    def valid_phone_number?
      if Phoner::Phone.valid? @phone_number
        true
      else
        [false, 'Phone number does not appear to be valid']
      end
    end

    has n, :supporters, constraint: :destroy
    
    def pretty_phone_number
      number = Phoner::Phone.parse phone_number
      number.format("+%c (%a) %n") + " [" + Phoner::Country.find_by_country_code(number.country_code).char_3_code + "]"
    end

  end
end