require 'rubygems'
require 'twilio-rb'
require 'sinatra'

configure do
  Twilio::Config.setup \
    :account_sid => ENV["TWILIO_ACCOUNT_SID"],
    :auth_token  => ENV["TWILIO_AUTH_TOKEN"]
end

def subscribers(number)
  count = Twilio::SMS.count :to => number
  pages = (count/1000.0).ceil 
  
  received = (0..pages-1).map do |page|
    Twilio::SMS.all :to => number, :page_size => 1000, :page => page
  end.flatten
  numbers = received.map {|m| m.from }.uniq
end

post '/smsresponse' do  
  Twilio::TwiML.build do |r|
    r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
          :from => params[:To], 
          :to => params[:From]
  end
end

post '/voiceresponse' do
  Twilio::TwiML.build do |r|
    r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
      :from => params[:To], 
      :to => @phone_number
    r.reject :reason => 'busy'
  end
end

get '/' do  
  @numbers = Twilio::IncomingPhoneNumber.all.map {|n| n.phone_number}

  @subscribers = params[:number].nil? ? [] : subscribers(params[:number])

  erb :subscribers
end

post '/broadcast' do
  from = params[:number]
  message = params[:message]

  subscribers(from).each do |to|
    Twilio::SMS.create :to => to, :from => from,
                       :body => message
  end
  redirect to('/')
end

