module Crowdring
  class ShortCode
    def self.parse(number)
      ShortCode.new if shortcode?(number) 
    end

    def self.shortcode?(number)
      number == ENV['ROUTO_NUMBER']
    end

    def country
      Phoner::Country.load
      Phoner::Country.find_by_name('Brazil')
    end
  end
end