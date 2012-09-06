require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

def account
  @client ||= begin
    sid = ENV["TWILIO_ACCOUNT_SID"]
    token = ENV["TWILIO_AUTH_TOKEN"]
    Twilio::REST::Client.new(sid, token)
  end

  @client.account
end

get '/' do
  names = account.outgoing_caller_ids.list({}).map do |outgoing_caller_id|
    outgoing_caller_id.friendly_name
  end
  
  names.join("<br>")
end

post '/smsresponse' do
  @phone_number = params[:From]
  
  account.sms.messages.create(
    :from => '+18143894106', 
    :to => @phone_number, 
    :body => 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'
  )
  
  "Sent message to " + @phone_number
end

post '/smsresponsetwiml' do
  @phone_number = params[:From]
  
  response = Twilio::TwiML::Response.new do |r|
    r.Sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
      :from => '+18143894106', :to => @phone_number
  end
  response.text
end

post '/voiceresponse' do
  response = Twilio::TwiML::Response.new do |r|
    r.Reject :reason => 'busy'
  end
  response.text
end

