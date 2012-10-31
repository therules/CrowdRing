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
    supports :voice, :sms
    request_handler(NetcoreRequest) {|inst| [inst.numbers.first]}

    def initialize(feedid, from, password)
      @feedid = feedid
      @from = from
      @password = password
    end

    def numbers
      ['+91'+ @from]
    end

    def send_sms(params)
      uri = URI('https://bulkpush.mytoday.com/BulkSms/SingleMsgApi')
      encoded_params = encode_params(params)
      uri.query = encoded_params
      response = send_request(uri)
    end

    private 

    def encode_params(params)
      to = params[:to].sub('+', '')
      message = params[:text]
      request_params = { feedid: @feedid, password: @password, text: message, from: @from, to: to}
      URI.encode_www_form(request_params)
    end

    def send_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request)
    end
  end
end
