require 'nexmo'

module Crowdring
  class NexmoRequest
    attr_reader :from, :to

    def initialize(request)
      @from = request.GET['msisdn']
      @to = request.GET['to']
    end

    def callback?
      false
    end
  end

  class NexmoService < TelephonyService
    supports :sms
    request_handler NexmoRequest

    def initialize(key, secret)
      @key = key 
      @secret = secret
      @client = Nexmo::Client.new(key, secret)
    end

    def numbers
      @client.get_account_numbers(size:100).object[:numbers].map {|n| n[:msisdn] }
    end

    def send_sms(params)
      @client.send_message to: params[:to],
        from: params[:from],
        text: params[:msg]
    end

    def broadcast(from, msg, to_numbers)
      params = {key: @key, secret: @secret}
      Resque.enqueue(NexmoBatchSendSms, params, from, msg, to_numbers)
    end
  end
end