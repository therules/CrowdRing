module Crowdring
  class LoggingRequest
    attr_reader :from, :to

    def initialize(request)
      @from = 'from'
      @to = 'to'
    end

    def callback?
      false
    end
  end

  class LoggingService 
    attr_reader :last_sms, :last_broadcast

    def initialize(numbers)
      @numbers = numbers
    end

    def supports_outgoing?
      true
    end

    def transform_request(request)
      LoggingRequest.new(request)
    end

    def build_response(from, commands)
      ''
    end

    def numbers
      @numbers
    end

    def send_sms(params)
      @last_sms = params
    end

    def broadcast(from, msg, to_numbers)
      @last_broadcast = {from: from, msg: msg, to_numbers: to_numbers }
    end

  end
end