require 'rubygems'
require 'twilio-rb'
require 'sinatra'

configure do
  Twilio::Config.setup \
    :account_sid => ENV["TWILIO_ACCOUNT_SID"],
    :auth_token  => ENV["TWILIO_AUTH_TOKEN"]
end

get '/' do
  count = Twilio::SMS.count :to => ENV["REC_NUMBER"]
  pages = (count/1000.0).ceil 
  
  received = (0..pages-1).map do |page|
    Twilio::SMS.all :to => ENV["REC_NUMBER"], :page_size => 1000, :page => page
  end.flatten
  numbers = received.map {|m| m.from }.uniq
  
  numbers.join("<br>")
end

post '/smsresponse' do
  @phone_number = params[:From]
  
  Twilio::SMS.create :from => '+18143894106', :to => @phone_number, 
    :body => 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'
  ""
end

post '/smsresponsetwiml' do
  @phone_number = params[:From]
  
  Twilio::TwiML.build do |r|
    r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
          :from => ENV["REC_NUMBER"], 
          :to => @phone_number
  end
end

post '/voiceresponse' do
  Twilio::TwiML.build do |r|
    r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
      :from => ENV["REC_NUMBER"], 
      :to => @phone_number
    r.reject :reason => 'busy'

  end
end

