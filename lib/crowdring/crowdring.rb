module Crowdring
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash
    set :logging, true
    set :root, File.dirname(__FILE__) + '/..'

    def self.service_handler
      CompositeService.instance
    end

    configure :development do
      register Sinatra::Reloader
      service_handler.add('logger', LoggingService.new(['+11111111111', '+12222222222'], output: true), default: true)
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
      
      database_url = ENV["DATABASE_URL"] || "postgres://localhost/crowdring_#{settings.environment}"
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

      if AssignedPhoneNumber.get(request.to)
        campaign = AssignedPhoneNumber.get(request.to).campaign
        supporter = Supporter.first_or_create(phone_number: from)
        campaign.join(supporter)
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

    get '/campaigns' do
      @campaigns = Campaign.all

      erb :campaigns
    end

    get '/campaign/new' do
      used_numbers = AssignedPhoneNumber.all.map(&:phone_number)
      @numbers = Server.service_handler.numbers - used_numbers

      erb :campaign_new
    end

    post '/campaign/create' do
      numbers = params.delete('phone_numbers_to_assign')
      campaign = Campaign.new(params)
      if campaign.save
        flash[:errors] = "Failed to assign numbers" unless campaign.assign_phone_numbers(numbers)
        flash[:notice] = "Campaign created"
        redirect to("/campaigns##{campaign.id}")
      else
        flash[:errors] = campaign.errors.full_messages.join('|')
        redirect to('/campaign/new')
      end
    end

    post '/campaign/:id/destroy' do
      Campaign.get(params[:id]).destroy

      flash[:notice] = "Campaign destroyed"
      redirect to('/')
    end

    get '/campaign/:id' do
      @campaign = Campaign.get(params[:id])
      if @campaign
        @supporters =  @campaign.supporters.all(order: [:created_at.desc], limit: 10)
        @supporter_count = @campaign.supporters.count
        @countries = @campaign.supporters.map(&:country).uniq
        @all_fields = CsvField.all_fields
        erb :campaign
      else
        flash[:errors] = "No campaign with id #{params[:id]}"
        404
      end
    end

    get '/campaign/:id/csv' do
      attachment("#{params[:id]}.csv")
      memberships = Filter.create(params[:filter]).filter(Campaign.get(params[:id]).memberships)
      fields = params.key?('fields') ? params[:fields].keys.map {|id| CsvField.from_id id } : CsvField.default_fields
      CSV.generate do |csv|
        csv << fields.map {|f| f.display_name }
        memberships.each {|s| csv << fields.map {|f| s.send(f.id) } }
      end
    end


    post '/campaign/:id/broadcast' do
      campaign = Campaign.get(params[:id])
      from = params[:from] || campaign.assigned_phone_numbers.first.phone_number
      message = params[:message]
      memberships = Filter.create(params[:filter]).filter(Campaign.get(params[:id]).memberships)
      to = memberships.map(&:supporter).map(&:phone_number)

      Server.service_handler.broadcast(from, message, to)
      campaign.most_recent_broadcast = DateTime.now
      campaign.save

      flash[:notice] = "Message broadcast"
      redirect to("/campaigns##{campaign.id}")
    end

    run! if app_file == $0
  end
end