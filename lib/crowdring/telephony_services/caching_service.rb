module Crowdring
  class CachingService 

    def initialize(service, seconds_to_expiry=300)
      @service = service
      @seconds_to_expiry = seconds_to_expiry
      refetch
    end

    def numbers
      refetch if expired?
      @numbers
    end

    def method_missing(method, *args, &block)
      @service.send(method, *args, &block)
    end

    private

    def expired?
      Time.now - @most_recent_updated > @seconds_to_expiry 
    end

    def refetch
      @most_recent_updated = Time.now
      @numbers = @service.numbers
    end  
  end
end
