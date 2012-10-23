 module Crowdring
  class RoutoService < TelephonyService
    supports :sms
        
    def initialize(username, password, number)
      @user_name = username
      @password = password
      @numbers = number
    end

    def send_sms(to, message, from=@numbers)
      uri = URI('http://smsc6.routotelecom.com/SMSsend?')
      back_up_uri = URI('http://smsc5.routotelecom.com/SMSsend?')
     
      params={ number: to, user: @user_name, password: @password, message: message, ownnum: from}
      uri.query  = URI.encode_www_form(params).gsub(/\+/, '%20')
      res = Net::HTTP.get_response(uri)
    end

    def numbers
      [@numbers]
    end

    def broadcast
      params = {key: @username, secret: @password}
      Resque.enqueue(RoutoBatchSendSms, params, from, msg, to_numbers)
    end
  end
end
