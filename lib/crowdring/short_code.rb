module Crowdring
  class ShortCode
    def self.parse(number)
      ShortCode.new if shortcode?(number) 
    end

    def self.shortcode?(number)
      number == ENV['ROUTO_NUMBER']
    end

    def country
      Phonie::Country.load
      Phonie::Country.find_by_name('Brazil')
    end
  end
end