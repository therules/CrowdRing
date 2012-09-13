require 'bundler'
require 'sinatra/base'
require 'data_mapper'
require 'pusher'
require 'rack-flash'
require 'facets/module/mattr'
require 'phone'

require 'crowdring/twilio_service'
require 'crowdring/kookoo_service'
require 'crowdring/composite_service'

require 'crowdring/campaign'
require 'crowdring/supporter'

module Crowdring
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash


    def service
      CompositeService.instance
    end

    configure do

      Pusher.app_id = ENV["PUSHER_APP_ID"]
      Pusher.key = ENV["PUSHER_KEY"]
      Pusher.secret = ENV["PUSHER_SECRET"]
        
      DataMapper.setup(:default, ENV["DATABASE_URL"])

      DataMapper.finalize
      DataMapper.auto_migrate!

      CompositeService.instance.add(:twilio, TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]))
      CompositeService.instance.add(:kookoo, KooKooService.new(ENV["KOOKOO_API_KEY"]))
      # Campaign.create(phone_number: '+18143894106', title: 'Test Campaign')
    end

    def sms_response(service_name, params)
      new_params = service.params(service_name, params)

      Campaign.get(new_params[:to]).supporters.first_or_create(phone_number: new_params[:from])
      msg = 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'
      service.build_response(new_params[:to], {cmd: :sendsms, to: new_params[:from], msg: msg})
    end

    def voice_response(service_name, params)
      new_params = service.params(service_name, params)

      Campaign.get(new_params[:to]).supporters.first_or_create(phone_number: new_params[:from])
      msg = 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'
      service.build_response(new_params[:to],
        {cmd: :sendsms, to: new_params[:from], msg: msg},
        {cmd: :reject}
      )
    end

    post '/smsresponse/:service' do
      sms_response(params[:service].to_sym, params)
    end

    get '/smsresponse/:service/' do
      sms_response(params[:service].to_sym, params)
    end

    post '/voiceresponse/:service' do
      voice_response(params[:service].to_sym, params)
    end

    get '/voiceresponse/:service' do 
      puts "cid: " + params[:service]
      voice_response(params[:service].to_sym, params)
    end

    get '/' do  
      @campaigns = Campaign.all

      erb :index
    end

    get '/campaign/new' do
      all_numbers = service.numbers
      used_numbers = Campaign.all.map {|n| n.phone_number }
      @numbers = all_numbers - used_numbers

      erb :campaign_new
    end

    post '/campaign/create' do
      Campaign.create(phone_number: params[:phone_number],
                      title: params[:title])
      
      flash[:notice] = "created campaign"
      redirect to("/##{params[:phone_number]}")
    end

    post '/campaign/destroy' do
      Campaign.get(params[:number]).destroy

      flash[:notice] = "campaign destroyed"
      redirect to('/')
    end

    get '/campaign/:number' do
      @campaign = Campaign.get(params[:number])
      @supporters =  @campaign.supporters
      erb :campaign
    end

    post '/broadcast' do
      from = params[:number]
      message = params[:message]

      Campaign.get(from).supporters.each do |to|
        service.send_sms(from: from, to:to.phone_number, msg: message)
      end

      flash[:notice] = "message broadcast"
      redirect to("/##{from}")
    end

    run! if app_file == $0
  end
end