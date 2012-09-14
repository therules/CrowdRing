require 'bundler'
require 'sinatra/base'
require 'data_mapper'
require 'pusher'
require 'rack-flash'
require 'facets/module/mattr'
require 'phone'

require 'crowdring/twilio_service'
require 'crowdring/kookoo_service'
require 'crowdring/tropo_service'
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
      DataMapper.auto_upgrade!

      CompositeService.instance.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]))
      CompositeService.instance.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], '+9104039411020'))
      CompositeService.instance.add('tropo.json', TropoService.new(ENV["TROPO_MSG_TOKEN"], ['+18143257247']))
      # Campaign.create(phone_number: '+18143894106', title: 'Test Campaign')
    end

    def sms_response
      ->(params) {
        [{cmd: :sendsms, to: params[:from], msg: params[:msg]}]
      }
    end

    def voice_response
      ->(params) {
        [{cmd: :sendsms, to: params[:from], msg: params[:msg]},
         {cmd: :reject}
        ]
      }
    end

    def respond(cur_service, request, commands)
      new_params = cur_service.extract_params(request)
      new_params[:msg] = 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'

      Campaign.get(new_params[:to]).supporters.first_or_create(phone_number: new_params[:from])
      cur_service.build_response(new_params[:to], commands.(new_params))
    end

    def process_request(service_name, request, response)
      cur_service = service.get(service_name)
      if cur_service.is_callback?(request)
        cur_service.process_callback(request)
      else
        respond(cur_service, request, response)
      end
    end

    post '/smsresponse/:service' do
      process_request(params[:service], request, sms_response)
    end

    get '/smsresponse/:service' do
      process_request(params[:service], request, sms_response)
    end

    post '/voiceresponse/:service' do
      process_request(params[:service], request, voice_response)
    end

    get '/voiceresponse/:service' do 
      process_request(params[:service], request, voice_response)
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