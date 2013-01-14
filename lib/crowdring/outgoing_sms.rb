module Crowdring
  class OutgoingSMS
    def initialize(opts)
      @from = opts[:from]
      @to = opts[:to]
      @text = opts[:text]
    end

    def price
      SMSPrices.price_for(CompositeService.instance.service_for(:sms, @from), Phonie::Phone.parse(@to))
    end
  end
end