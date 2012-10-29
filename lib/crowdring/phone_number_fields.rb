module Crowdring
  module PhoneNumberFields
    def pretty_phone_number
      return phone_number unless Phoner::Phone.valid? phone_number
      number = Phoner::Phone.parse phone_number
      Phoner::Phone.n1_length = 4 if country_code == '91'
      number.format "+%c (%a) %f-%l" + " [" + country.char_3_code + "]"
    end

    def country_code
      Phoner::Phone.parse(phone_number).country_code
    end

    def country_abbreviation
      country.char_3_code
    end

    def country_name
      country.name
    end

    def area_code
      Phoner::Phone.parse(phone_number).area_code
    end

    def country
      number.country
    end

    def number
      Phoner::Phone.parse phone_number
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