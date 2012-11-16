module Crowdring
  module SMSPrices
    @@prices = nil

    module_function

    def default_prices
      return @@prices unless @@prices.nil?

      data_file = File.join(File.dirname(__FILE__), '../..', 'data', 'sms_prices.yml')
      @@prices = YAML.load(File.read(data_file))
    end

    def price_for(service, number, opts={})
      prices = opts[:prices] || default_prices
      if prices[service]
        short_code = ShortCode.parse(number)
        short_code ? prices[service][short_code.country.char_3_code] : prices[service][number.country.char_3_code]
      end
    end
  end
end