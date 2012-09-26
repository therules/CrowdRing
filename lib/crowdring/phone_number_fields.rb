module Crowdring
  module PhoneNumberFields
    def pretty_phone_number
      number = Phoner::Phone.parse phone_number
      number.format "+%c (%a) %n" + " [" + country.char_3_code + "]"
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
      Phoner::Country.find_by_country_code(number.country_code)
    end

    private

    def number
      Phoner::Phone.parse phone_number
    end

    def valid_phone_number?
      if Phoner::Phone.valid? @phone_number
        true
      else
        [false, 'Phone number does not appear to be valid']
      end
    end
  end
end