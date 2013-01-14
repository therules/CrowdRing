module Crowdring
  module PhoneNumberFields
    def pretty_phone_number
      return phone_number unless Phonie::Phone.valid? phone_number
      number = Phonie::Phone.parse phone_number
      Phonie::Phone.n1_length = (country_code == '91') ? 4 : 3
      number.format "+%c (%a) %f-%l" + " [" + country.char_3_code + "]"
    end

    def country_code
      Phonie::Phone.parse(phone_number).country_code
    end

    def country_abbreviation
      country.char_3_code
    end

    def country_name
      country.name
    end

    def area_code
      Phonie::Phone.parse(phone_number).area_code
    end

    def country
      short_code =  ShortCode.parse(phone_number)
      short_code ? short_code.country : number.country
    end

    def number
      Phonie::Phone.parse phone_number
    end

    module_function

    def pretty_number(number_str)
      PrettyNumber.new(number_str).pretty_phone_number
    end

    private

    class PrettyNumber < Struct.new(:phone_number)
      include PhoneNumberFields
    end

    def valid_phone_number?
      if Phonie::Phone.valid? @phone_number
        true
      else
        [false, 'Phone number does not appear to be valid']
      end
    end
  end
end