require 'twilio-ruby'

class TwilioService 

  def initialize(account_sid, auth_token)
    @client = Twilio::REST::Client.new account_sid, auth_token
  end

  def params(params)
    {from: params[:From], to: params[:To]}
  end

  def build_response(from, *commands)
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
    @client.account.incoming_phone_numbers.list.map {|n| n.phone_number }
  end

  def send_sms(params)
    @client.account.sms.messages.create(
      to: params[:to], 
      from: params[:from],
      body: params[:msg]
    )
  end
end