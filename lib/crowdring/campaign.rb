module Crowdring
  class Campaign
    include DataMapper::Resource

    property :phone_number, String, key: true
    property :title,        String

    has n, :supporters, constraint: :destroy
    
    def pretty_phone_number
      number = Phoner::Phone.parse phone_number
      number.format("+%c (%a) %n") + " [" + Phoner::Country.find_by_country_code(number.country_code).char_3_code + "]"
    end

  end
end