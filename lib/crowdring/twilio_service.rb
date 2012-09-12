require 'twilio-rb'

class TwilioService 

  def initialize
    Twilio::Config.setup \
      account_sid: ENV["TWILIO_ACCOUNT_SID"],
      auth_token: ENV["TWILIO_AUTH_TOKEN"]
  end

  def params(params)
    {from: params[:From], to: params[:To]}
  end

  def build_response(from, *commands)
    Twilio::TwiML.build do |r|
      commands.each do |c|
        case c[:cmd]
        when :sendsms
          r.sms c[:msg], from: from, to: c[:to]
        when :reject
          r.reject reason: 'busy'
        end
      end
    end
  end

  def numbers
    Twilio::IncomingPhoneNumber.all.map {|n| n.phone_number }
  end

  def send_sms(params)
    Twilio::SMS.create(to: params[:to], from: params[:from],
                       body: params[:msg])
  end
end