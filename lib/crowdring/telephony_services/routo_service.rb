 module Crowdring
  class RoutoService < TelephonyService
    supports :sms
        
    def initialize(username, password, number)
      @user_name = username
      @password = password
      @number = number
    end

    def send_sms(params)
      uri = URI('https://smsc5.routotelecom.com/SMSsend')
      back_up_uri = URI('https://smsc6.routotelecom.com/SMSsend')

      uri.query  = parse_params params
      response = send_out_msg uri
      p response
      if response.body == 'failed' || response.body == 'sys_error' || response.body == 'bad_operator'
        back_up_uri.query = parse_params parse_params
        send_out_msg back_up_uri
      end  
    end

    def numbers
      [@number]
    end

    def broadcast
      params = {key: @username, secret: @password}
      Resque.enqueue(RoutoBatchSendSms, params, from, msg, to_numbers)
    end

    def parse_params params
      to = params[:to].sub('+','')
      from = params[:from].sub('+','')
      message = params[:msg]
      
      params={ number: to, user: @user_name, pass: @password, message: message, ownnum: from}
      URI.encode_www_form(params).gsub(/\+/, '%20')
    end

    def send_out_msg uri
      p uri
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
    end
  end
end
