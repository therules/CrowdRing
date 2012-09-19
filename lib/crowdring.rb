require 'bundler'
require 'sinatra/base'
require 'sinatra/reloader'
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
    configure :development do
      register Sinatra::Reloader
    end
    enable :sessions
    use Rack::Flash
    set :logging, true

    def service
      CompositeService.instance
    end

    configure do
      $stdout.sync = true

      Pusher.app_id = ENV["PUSHER_APP_ID"]
      Pusher.key = ENV["PUSHER_KEY"]
      Pusher.secret = ENV["PUSHER_SECRET"]
        
      DataMapper.setup(:default, ENV["DATABASE_URL"])

      DataMapper.finalize
      DataMapper.auto_upgrade!

      CompositeService.instance.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]), :default)
      CompositeService.instance.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], ENV["KOOKOO_NUMBER"]))
      # CompositeService.instance.add('tropo.json', TropoService.new(ENV["TROPO_MSG_TOKEN"], ENV["TROPO_APP_ID"], 
      #   ENV["TROPO_USERNAME"], ENV["TROPO_PASSWORD"]))
      # # Campaign.create(phone_number: '+18143894106', title: 'Test Campaign')
    end

    def sms_response
      proc {|to, msg| 
        []
      }
    end

    def voice_response
      proc {|to, msg|
        [{cmd: :reject}]
      }
    end

    def respond(cur_service, request, response)
      msg = 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.'

      from = Phoner::Phone.normalize request.from
      Campaign.get(request.to).supporters.first_or_create(phone_number: from)

      service.send_sms(to: from, from: request.to, msg: msg)
      cur_service.build_response(request.to, response.(from, msg))
    end

    def process_request(service_name, request, response)
      cur_service = service.get(service_name)
      cur_request = cur_service.transform_request(request)

      if cur_request.callback?
        cur_service.process_callback(cur_request)
      else
        respond(cur_service, cur_request, response)
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
      used_numbers = Campaign.all.map(&:phone_number)
      @numbers = service.numbers - used_numbers

      erb :campaign_new
    end

    post '/campaign/create' do
      Campaign.create(phone_number: params[:phone_number],
                      title: params[:title])
      
      flash[:notice] = "campaign created"
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
        puts "[%s] %s" % [ Time.now, "/broadcast: Sending SMS to #{to.phone_number}"]
        service.send_sms(from: from, to: to.phone_number, msg: message)
      end

      flash[:notice] = "message broadcast"
      redirect to("/##{from}")
    end

    run! if app_file == $0
  end
end