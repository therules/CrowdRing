module Crowdring
  class PriceEstimate
    attr_accessor :total_price, :unpriceable_items, :total_item_count

    def initialize(priced_items)
      @total_price = 0.0
      @unpriceable_items = []
      @total_item_count = priced_items.count
      
      priced_items.each do |item|
        price = item.price
        if price
          @total_price += price
        else
          @unpriceable_items << item
        end
      end
    end
  end
end