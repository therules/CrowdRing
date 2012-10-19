require 'twilio-ruby'

module Crowdring
  class TwilioRequest
    attr_reader :from, :to

    def initialize(request)
      params = request.POST
      @from = params['From']
      @to = params['To']
    end

    def callback?
      false
    end
  end

  class TwilioService < TelephonyService
    supports :voice, :sms
    request_handler TwilioRequest

    def initialize(account_sid, auth_token)
      @account_sid = account_sid
      @auth_token = auth_token
      @client = Twilio::REST::Client.new account_sid, auth_token
    end

    def build_response(from, commands)
      response = Twilio::TwiML::Response.new do |r|
        commands.each do |c|
          case c[:cmd]
          when :sendsms
            r.Sms c[:msg], from: from, to: c[:to]
          when :reject
            r.Reject reason: 'busy'
          end
        end
      end
      response.text
    end

    def numbers
      @client.account.incoming_phone_numbers.list.map(&:phone_number)
    end

    def send_sms(params)
      @client.account.sms.messages.create(
        to: params[:to], 
        from: params[:from],
        body: params[:msg]
      )
    end

    def broadcast(from, msg, to_numbers)
      params = {account_sid: @account_sid, auth_token: @auth_token}
      Resque.enqueue(TwilioBatchSendSms, params, from, msg, to_numbers)
    end

  end
end