module Crowdring
  class ShortCode
    def self.parse(number)
      return ShortCode.new if number == ENV['ROUTO_NUMBER']
    end

    def country
      Phoner::Country.load
      Phoner::Country.find_by_name('Brazil')
    end
  end
end