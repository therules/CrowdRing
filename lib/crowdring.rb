require 'bundler'
require 'sinatra/base'
require 'sinatra/reloader'
require 'data_mapper'
require 'pusher'
require 'rack-flash'
require 'facets/module/mattr'
require 'phone'
require 'resque'

require 'crowdring/twilio_service'
require 'crowdring/kookoo_service'
require 'crowdring/tropo_service'
require 'crowdring/composite_service'
require 'crowdring/batch_send_sms'

require 'crowdring/campaign'
require 'crowdring/supporter'

module Crowdring
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash
    set :logging, true

    def self.service_handler
      if settings.environment == :development
        FakeCompositeService.instance
      else
        CompositeService.instance
      end
    end

    configure :development do
      register Sinatra::Reloader

      service_handler.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]), default: true)
      service_handler.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], ENV["KOOKOO_NUMBER"]))
      
    end

    configure :production do
      service_handler.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]), default: true)
      service_handler.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], ENV["KOOKOO_NUMBER"]))
      service_handler.add('tropo.json', TropoService.new(ENV["TROPO_MSG_TOKEN"], ENV["TROPO_APP_ID"], 
        ENV["TROPO_USERNAME"], ENV["TROPO_PASSWORD"]))
    end

    configure do
      $stdout.sync = true

      Pusher.app_id = ENV["PUSHER_APP_ID"]
      Pusher.key = ENV["PUSHER_KEY"]
      Pusher.secret = ENV["PUSHER_SECRET"]
      
      database_url = ENV["DATABASE_URL"] || 'postgres://localhost/crowdring'
      DataMapper.setup(:default, database_url)
      DataMapper.finalize

      redis_url = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
      uri = URI.parse(redis_url)
      Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
    end


    helpers do
      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['USERNAME'], ENV['PASSWORD']]
      end
    end

    before { protected! unless request.path_info =~ /(voice|sms)response/ }

    def sms_response
      proc {|to| 
        []
      }
    end

    def voice_response
      proc {|to|
        [{cmd: :reject}]
      }
    end

    def respond(cur_service, request, response)
      from = Phoner::Phone.normalize request.from
      campaign = Campaign.get(request.to)

      if campaign
        campaign.supporters.first_or_create(phone_number: from)
        Server.service_handler.send_sms(to: from, from: request.to, msg: campaign.introductory_message)
      end

      cur_service.build_response(request.to, response.(from))
    end

    def process_request(service_name, request, response)
      cur_service = Server.service_handler.get(service_name)
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
      @numbers = Server.service_handler.numbers - used_numbers

      erb :campaign_new
    end

    post '/campaign/create' do
      campaign = Campaign.new(params)
      if campaign.save
        flash[:notice] = "Campaign created"
        redirect to("/##{params[:phone_number]}")
      else
        flash[:errors] = campaign.errors.full_messages.join('|')
        redirect to('/campaign/new')
      end
    end

    post '/campaign/destroy' do
      Campaign.get(params[:phone_number]).destroy

      flash[:notice] = "Campaign destroyed"
      redirect to('/')
    end

    get '/campaign/:phone_number' do
      @campaign = Campaign.get(params[:phone_number])
      if @campaign
        @supporters =  @campaign.supporters.all(order: [:created_at.desc], limit: 10)
        @supporter_count = @campaign.supporters.count
        erb :campaign
      else
        flash[:errors] = "No campaign with number #{params[:phone_number]}"
        404
      end
    end

    get '/campaign/:phone_number/csv' do
      headers "Content-Disposition" => "attachment;filename=#{params[:phone_number]}.csv",
              "Content-Type" => "application/octet-stream"
      supporters = case params[:receivers]
        when "all"
          Campaign.get(params[:phone_number]).supporters
        when "new"
          Campaign.get(params[:phone_number]).new_supporters
      end
      CSV.generate do |csv|
        csv << ['Phone Number', 'Support Date']
        supporters.each {|s| csv << [s.phone_number, s.created_at.strftime('%F')] }
      end
    end


    post '/broadcast' do
      from = params[:phone_number]
      campaign = Campaign.get(from)
      message = params[:message]
      to = case params[:receivers]
        when "all"
          campaign.supporters
        when "new"
          campaign.new_supporters
      end
      to = to.map(&:phone_number)

      Server.service_handler.broadcast(from, message, to)
      campaign.most_recent_broadcast = DateTime.now
      campaign.save

      flash[:notice] = "Message broadcast"
      redirect to("/##{from}")
    end

    run! if app_file == $0
  end
end