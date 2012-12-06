require "sinatra/json"
require "sinatra/jsonp"

module Crowdring
  def self.statsd
    @statsd ||= Statsd.new(ENV['STATSD_HOST'] || "http://localhost").tap do |s|
      s.namespace = "crowdring"
    end
  end

  class Server < Sinatra::Base
    helpers Sinatra::JSON
    helpers Sinatra::Jsonp
    register Sinatra::SinatraAuthentication
    enable :sessions
    use Rack::Flash
    set :logging, true
    set :root, File.dirname(__FILE__) + '/..'
    set :sinatra_authentication_view_path, settings.views + "/auth/"
    set :protection, except: :frame_options

    include LazyHighCharts::LayoutHelper

    def self.service_handler
      CompositeService.instance
    end

    configure :development do
      register Sinatra::Reloader
      service_handler.add('voice_logger', VoiceLoggingService.new(['+18001111111', '+555130793000','+18003333333', '+18004444444', '+18002222222', '+919102764633','+27114891922'], output: true))
      service_handler.add('sms_logger', SMSLoggingService.new(['+18001111111', '+18002222222', '+919102764622', '+27114891911'], output: true))
    end

    configure :production do
      use Rack::SSL
      service_handler.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]))
      service_handler.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], ENV["KOOKOO_NUMBER"]))
      # service_handler.add('tropo.json', TropoService.new(ENV["TROPO_MSG_TOKEN"], ENV["TROPO_APP_ID"], 
      #   ENV["TROPO_USERNAME"], ENV["TROPO_PASSWORD"]))
      service_handler.add('voxeo', VoxeoService.new(ENV["VOXEO_APP_ID"], ENV["VOXEO_USERNAME"], ENV["VOXEO_PASSWORD"]))
      service_handler.add('nexmo', NexmoService.new(ENV["NEXMO_KEY"], ENV["NEXMO_SECRET"]))
      service_handler.add('routo', RoutoService.new(ENV["ROUTO_USERNAME"], ENV["ROUTO_PASSWORD"], ENV["ROUTO_NUMBER"]))
      service_handler.add('netcore', NetcoreService.new(ENV["NETCORE_FEEDID"], ENV['NETCORE_FROM'], ENV['NETCORE_PASSWORD']))
      service_handler.add('plivo', PlivoService.new(ENV["PLIVO_AUTH_ID"], ENV["PLIVO_AUTH_TOKEN"]))
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
      def to_attributes(options)
        options.map {|k, v| v.nil? ? '' : " #{k}='#{v}'"}.join
      end
      
      def content_tag(type, content, options={})
        "<#{type}#{to_attributes(options)}>#{content}</#{type}>"
      end

      def pretty_phone_number(phone_number)
        PhoneNumberFields.pretty_number(phone_number)
      end

      def pluralize(count, noun)
        "#{count} #{noun}#{count != 1 ? 's' : ''}"
      end
    end

    before /^((?!((voice|sms)response)|reports|login|resetpassword|voicemails|progress-embed|campaign\-member\-count).)*$/ do
      login_required unless settings.environment == :test
    end

    before /(voice|sms)response/ do
      Crowdring.statsd.increment "#{$1}_received.count"
    end
    
    def respond(cur_service, request, response_type)
      response = AssignedPhoneNumber.handle(response_type, request)
      cur_service.build_response(request.to, response || [{cmd: :reject}])
    end

    def process_request(service_name, request, response_type)
      cur_service = Server.service_handler.get(service_name)
      cur_request = cur_service.transform_request(request)

      if cur_request.callback?
        cur_service.process_callback(cur_request)
      else
        respond(cur_service, cur_request, response_type)
      end
    end

    post '/smsresponse/:service' do
      process_request(params[:service], request, :sms)
    end

    get '/smsresponse/:service' do
      process_request(params[:service], request, :sms)
    end

    post '/voiceresponse/:service' do
      process_request(params[:service], request, :voice)
    end

    get '/voiceresponse/:service' do 
      process_request(params[:service], request, :voice)
    end

    get '/reports/netcore' do
      process_request('netcore', request, :voice)
    end

    get '/' do  
      @campaigns = Campaign.all
      @unsubscribe_numbers = AssignedUnsubscribeVoiceNumber.all
      @unsubscribed_count = Ringer.unsubscribed.count
      @aggregate_campaigns = AggregateCampaign.all

      haml :index
    end

    
    get '/unsubscribe_numbers/new' do
      @voice_numbers = NumberPool.available_summary

      haml :assign_unsubscribe_number
    end

    post '/unsubscribe_numbers/create' do
      unless params[:region]
        flash[:errors] = 'Please select a number'
        redirect to('/unsubscribe_numbers/new')
      end

      country, region = params[:region].split('|')
      res = {country: country}
      res[:region] = region if region
      number = NumberPool.find_number(res)

      unsubscribe_number = AssignedUnsubscribeVoiceNumber.new(phone_number: number)
      if unsubscribe_number.save
        flash[:notice] = "Unsubscribe number assigned"
        redirect to("/")
      else
        flash[:errors] = unsubscribe_number.errors.full_messages.join('|')
        redirect to('/unsubscribe_numbers/new')
      end
    end

    post '/unsubscribe_numbers/:id/destroy' do
      unsubscribe_number = AssignedUnsubscribeVoiceNumber.first(id: params[:id])
      if unsubscribe_number.destroy
        flash[:notice] = "Unsubscribe number removed"
      else
        flash[:errors] = "Failed to remove number|" + unsubscribe_number.errors.full_messages.join('|')
      end

      redirect to('/')
    end

    get '/campaigns' do
      @campaigns = Campaign.all

      haml :campaigns
    end

    get '/campaign/new' do
      @voice_numbers = NumberPool.available_voice_with_sms

      haml :campaign_new
    end

    get '/campaign/new/configure' do
      @title = params[:campaign][:title]

      begin
        @goal = Integer(params[:campaign][:goal])
      rescue ArgumentError
        flash[:errors] = "Must set a valid goal"
        redirect to('campaign/new')
      end

      unless params[:campaign][:regions]
        flash[:errors] = "Must select at least one region"
        redirect to('campaign/new')
      end

      unless @title 
        flash[:errors] = "Title can not be empty"
        redirect to('campaign/new')
      end

      regions = params[:campaign][:regions].map do |str|
        country, region = str.split('|')
        res = {country: country}
        res[:region] = region if region
        res
      end
      numbers = NumberPool.find_numbers(regions)
      @number_summary = numbers.zip(regions).map {|number, region| {number: number, region: region}}
      @sms_number = NumberPool.find_number(regions.first, :sms) || NumberPool.find_number({country: regions.first[:country]}, :sms)

      case params[:init_ask]
      when 'missed_call'
        haml :campaign_new_missed_call
      when 'sms_back'
        haml :campaign_new_sms_back
      when 'double_opt_in'
        haml :campaign_new_double_opt_in
      end
    end

    post '/campaign/create/missed_call' do
      campaign = Campaign.new(params[:campaign])
      if campaign.save
        flash[:notice] = "Campaign created"
        redirect to("/campaigns##{campaign.id}")
      else
        flash[:errors] = campaign.all_errors.map(&:full_messages).flatten.join('|')
        redirect to('/campaign/new')
      end
    end

    post '/campaign/create/sms_back' do
      campaign = Campaign.new(params[:campaign])
      if campaign.save
        filtered_messages = params[:sms_responses].zip(campaign.voice_numbers).map do |msg, number|
          FilteredMessage.new(constraints: [HasConstraint.create(tag: number.tag)], message_text: msg)
        end
        message = Message.create(filtered_messages: filtered_messages)
        send_sms_ask = SendSMSAsk.create(title: "Send SMS back - #{campaign.title}", message: message)
        campaign.asks.first.triggered_ask = send_sms_ask
        campaign.asks << send_sms_ask
        if campaign.save
          flash[:notice] = "Campaign created"
          redirect to("/campaigns##{campaign.id}")
        else
          flash[:errors] = campaign.all_errors.map(&:full_messages).flatten.join('|')
          redirect to('/campaign/new')
        end
      end
    end

    post '/campaign/create/double_opt_in' do
      campaign = Campaign.new(params[:campaign])
      if campaign.save
        message = params[:sms_response]
        filtered_messages = params[:sms_responses].zip(campaign.voice_numbers).map do |msg, number|
          FilteredMessage.new(constraints: [HasConstraint.create(tag: number.tag)], message_text: msg)
        end
        message = Message.create(filtered_messages: filtered_messages)
        join_ask = JoinAsk.create(title: "Join - #{campaign.title}", message: message)
        campaign.asks.first.triggered_ask = join_ask
        campaign.asks << join_ask
        if campaign.save
          flash[:notice] = "Campaign created"
          redirect to("/campaigns##{campaign.id}")
        else
          flash[:errors] = campaign.all_errors.map(&:full_messages).flatten.join('|')
          redirect to('/campaign/new')
        end
      end
    end
    
    get '/campaign/:id/voice_numbers/new' do
      @campaign = Campaign.get(params[:id])
      @voice_numbers = NumberPool.available_summary
      
      haml :campaign_assign_voice_number        
    end

    post '/campaign/:id/voice_numbers/create' do
      unless params[:region]
        flash[:errors] = 'Please select a number'
        redirect to("/campaign/#{params[:id]}/voice_numbers/new")
      end

      country, region = params[:region].split('|')
      res = {country: country}
      res[:region] = region if region
      number = NumberPool.find_number(res)

      campaign = Campaign.get(params[:id])
      campaign.voice_numbers.new(phone_number: number, description: params[:description])
      if campaign.save
        flash[:notice] = "Voice number assigned"
       redirect to("/campaigns##{campaign.id}")
      else
        flash[:errors] = campaign.all_errors.map(&:full_messages).flatten.join('|')
        redirect to("/campaign/#{campaign.id}/voice_numbers/new")
      end
    end

    post '/campaign/:id/voice_numbers/:number_id/destroy' do
      campaign = Campaign.get(params[:id])
      unless campaign.voice_numbers.count == 1
        campaign.voice_numbers.first(id: params[:number_id]).destroy
        flash[:notice] = "Voice number has been removed"
        redirect to("/campaigns##{campaign.id}")
      else
        flash[:errors] = "Must have at least one voice number"
        redirect to("/campaigns##{campaign.id}")
      end
    end

    get '/campaign/:id/asks/new' do
      @campaign = Campaign.get(params[:id])
      @ask_type = Ask.descendants.reject {|a| [:offline_ask, :join_ask].include?(a.typesym)}

      haml :campaign_add_new_ask
    end

    post '/campaign/:id/asks/create' do
      campaign = Campaign.get(params[:id])

      ask_type = params[:ask_type]
      unless ask_type
        flash[:errors] = "Ask type can not be empty"
        redirect to("/campaign/#{campaign.id}/asks/new")
      end
      ask_name = Ask.descendants.find{|a| a.typesym == ask_type.to_sym}
      message = params[:ask][:message]
      if params[:prompt]
        ask = Ask.create(title: params[:ask][:title], type: ask_name, message: message, prompt: params[:prompt])
      else
        ask = Ask.create(title: params[:ask][:title], type: ask_name, message: message)
      end

      campaign.asks << ask
      if campaign.save
        flash[:notice] = "New Ask Add"
        redirect to("/campaigns##{campaign.id}")
      else
        flash[:errors] = "#{ask.errors.full_messages.join('|')}"
        redirect to("/campaign/#{campaign.id}/asks/new")
      end
    end

    post '/campaign/:id/asks/:ask_id/destroy' do
      campaign = Campaign.get(params[:id])
      ask = campaign.asks.get(params[:ask_id])
      if campaign.asks.delete(ask) && campaign.save && ask.destroy
        flash[:notice] = 'Ask successfully removed.'
      else
        flash[:errors] = 'Failed to remove ask'
      end

      redirect to("/campaigns##{campaign.id}")
    end

    get '/campaign/:id/asks/:ask_id/edit' do
      @campaign_id = params[:id]
      @ask = Campaign.get(params[:id]).asks.get(params[:ask_id])

      haml :campaign_edit_ask
    end

    post '/campaign/:id/asks/:ask_id/update' do
      ask = Campaign.get(params[:id]).asks.get(params[:ask_id])
      if ask.update(params[:ask]) && ask.message.save 
        flash[:notice] = "#{ask.title} has been updated."
        redirect to("/campaigns##{params[:id]}")
      else
        flash[:errors] = "#{ask.errors.full_messages.join('|')}"
        redirect to("/campaign/#{params[:id]}/asks/#{params[:ask_id]}/edit")
      end
    end


    post '/campaign/:id/asks/:ask_id/trigger' do
      campaign = Campaign.get(params[:id])
      ask = campaign.asks.get(params[:ask_id])
      ringers = ask.potential_recipients(Ringer.subscribed)
      ask.trigger(ringers, campaign.sms_number.raw_number)
      redirect to("/campaigns##{campaign.id}")
    end


    post '/campaign/:id/destroy' do
      campaign = Campaign.get(params[:id])
      if campaign.destroy
        flash[:notice] = "Campaign destroyed"
      else
        flash[:errors] = "Failed to destroy campaign|" + campaign.errors.full_messages.join('|')
      end

      redirect to('/')
    end

    get '/campaign/:id' do
      @campaign = Campaign.get(params[:id])
      if @campaign
        @ringers =  @campaign.rings.all(order: [:created_at.desc], limit: 10).map(&:ringer)
        @ring_count = @campaign.rings.count
        @ringer_count = @campaign.ringers.count
        @countries = @campaign.ringers.map(&:country).uniq
        @all_fields = CsvField.all_fields
        @basic_chart = HighChartsBuilder.basic_stats(@campaign)
        @sms_cost = SMSPrices.price_for(CompositeService.instance.service_for(:sms, @campaign.sms_number.raw_number), @campaign.sms_number)

        haml :campaign, layout: !request.xhr?
      else
        flash[:errors] = "No campaign with id #{params[:id]}"
        404
      end
    end

    #this should actually be /aggregate_campaign/ but a change is required in the purpose platform for that
    get '/campaign/:name/campaign-member-count' do
      aggregate_campaign = AggregateCampaign.get(params[:name])
      if aggregate_campaign
        result = {count: aggregate_campaign.ringer_count}
        jsonp result, params[:callback]
      end
    end

    get '/campaign/:id/edit-goal' do
      @campaign = Campaign.get(params[:id])
      if @campaign
        @goal = @campaign.goal
        haml :campaign_edit_goal
      else
        flash[:errors] = "No campaign with id #{params[:id]}"
        404
      end
    end

    post '/campaign/:id/edit-goal' do
      campaign = Campaign.get(params[:id])
      if campaign.update(goal: params[:goal])
        flash[:notice] = "Campaign goal updated"
        redirect to("/campaigns##{params[:id]}")
      else
        flash[:errors] = "Failed to update campaign goal|" + campaign.errors.full_messages.join('|')
        redirect to("/campaign/#{params[:id]}/edit-goal")
      end

    end

    get '/campaign/:id/progress-embed' do
      @campaign = Campaign.get(params[:id])
      @color = params[:color]
      haml :campaign_progress_embedded, layout: false
    end

    get '/campaign/:id/csv' do
      attachment("#{params[:id]}.csv")
      rings = Filter.create(params[:filter]).filter(Campaign.get(params[:id]).unique_rings)
      fields = params.key?('fields') ? params[:fields].keys.map {|id| CsvField.from_id id } : CsvField.default_fields
      CSV.generate do |csv|
        csv << fields.map {|f| f.display_name }
        rings.each {|ring| csv << fields.map {|f| ring.send(f.id) } }
      end
    end


    post '/campaign/:id/broadcast' do
      campaign = Campaign.get(params[:id])
      from = params[:from] || campaign.sms_number.raw_number
      message = params[:message]
      unless message
        flash[:errors] = "Ask needs a prompt to launch"
        redirect to("/campaigns##{campaign.id}")
      end

      rings = Filter.create(params[:filter]).filter(Campaign.get(params[:id]).rings)
      to = rings.map(&:ringer).map(&:phone_number)

      Server.service_handler.broadcast(from, message, to)

      flash[:notice] = "Message broadcast"
      redirect to("/campaigns##{campaign.id}")
    end

    get '/aggregate_campaigns/new' do
      @campaigns = Campaign.all

      haml :aggregate_campaign_new
    end

    post '/aggregate_campaigns/create' do
      agg_campaign = AggregateCampaign.new(params[:aggregate_campaign])
      if agg_campaign.save
        flash[:notice] = 'Aggregate campaign created'
        redirect to('/')
      else
        flash[:errors] = agg_campaign.errors.full_messages.join('|')
        redirect to('/aggregate_campaigns/new')
      end
    end

    get '/aggregate_campaigns/:name/edit' do
      @campaigns = Campaign.all
      @aggregate_campaign = AggregateCampaign.get(params[:name])

      haml :aggregate_campaign_edit
    end

    post '/aggregate_campaigns/:name/update' do
      params[:aggregate_campaign][:campaigns] = [] unless params[:aggregate_campaign][:campaigns]
      agg_campaign = AggregateCampaign.get(params[:name])
      if agg_campaign.update(params[:aggregate_campaign])
        flash[:notice] = 'Aggregate campaign updated'
        redirect to('/')
      else
        flash[:errors] = agg_campaign.errors.full_messages.join('|')
        redirect to("/aggregate_campaigns/#{params[:name]}/edit")
      end
    end

    get '/tags/new' do
      haml :tag_new
    end

    post '/tags/create' do
      tag = Tag.from_str(params[:type] + ':' + params[:value])
      if tag.saved?
        flash[:notice] = "#{tag} tag created"
        redirect to('/')
      else
        flash[:errors] = tag.errors.full_messages.join('|')
        redirect to('/tags/new')
      end
    end

    get '/tags/tags.json' do
      content_type :json

      Tag.visible.map {|tag| {category: tag.readable_group, visible_label: tag.readable_value, label: tag.readable_s, value: tag.to_s} }.to_json
    end

    get '/tags/grouped_tags.json' do
      content_type :json

      grouped = Tag.visible.reduce({}) do |grouped, tag|
        grouped[tag.readable_group] = [] unless grouped.key? tag.readable_group
        grouped[tag.readable_group] << tag
        grouped
      end
      grouped.each_with_object({}) {|(key, value), grouped| grouped[key] = value.map {|tag| {category: tag.readable_group, visible_label: tag.readable_value, label: tag.readable_s, value: tag.to_s} }}.to_json
    end

    post '/voicemails/:id/plivo' do
      voicemail = Voicemail.get(params[:id])
      voicemail.update(filename: params[:RecordUrl])
    end

    not_found do
      haml :not_found
    end

    run! if app_file == $0
  end
end