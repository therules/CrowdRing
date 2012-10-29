module Crowdring
  class NetcoreRequest
    attr_reader :from, :to

    def initialize(request, to)
      @to = to
      @from = request.GET['msisdn']
    end

    def callback?
      false
    end
  end

  class NetcoreService < TelephonyService
    supports :voice
    request_handler(NetcoreRequest) {|inst| [inst.numbers.first]}

    def initialize(number)
      @number = number
    end

    def build_response(from, commands)
      ''
    end

    def numbers
      [@number]
    end

  end
end