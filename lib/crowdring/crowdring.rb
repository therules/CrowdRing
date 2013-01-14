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
    use Rack::Flash, sweep: true
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
      service_handler.add('sms_logger', SMSLoggingService.new(['+18001111111', '+18002222222', '+919102764622', '+27114891911'], output: true))
      service_handler.add('voice_logger', VoiceLoggingService.new(['+18001111111', '+18002222222', '+919102764622', '+27114891911'], output: true))
    end

    configure :production do
      use Rack::SSL
      service_handler.add('twilio', TwilioService.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]))
      # service_handler.add('kookoo', KooKooService.new(ENV["KOOKOO_API_KEY"], ENV["KOOKOO_NUMBER"]))
      # service_handler.add('tropo.json', TropoService.new(ENV["TROPO_MSG_TOKEN"], ENV["TROPO_APP_ID"],
      #   ENV["TROPO_USERNAME"], ENV["TROPO_PASSWORD"]))
      # service_handler.add('voxeo', VoxeoService.new(ENV["VOXEO_APP_ID"], ENV["VOXEO_USERNAME"], ENV["VOXEO_PASSWORD"]))
      # service_handler.add('nexmo', NexmoService.new(ENV["NEXMO_KEY"], ENV["NEXMO_SECRET"]))
      # service_handler.add('routo', RoutoService.new(ENV["ROUTO_USERNAME"], ENV["ROUTO_PASSWORD"], ENV["ROUTO_NUMBER"]))
      # service_handler.add('netcore', NetcoreService.new(ENV["NETCORE_FEEDID"], ENV['NETCORE_FROM'], ENV['NETCORE_PASSWORD']))
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

      def limit_length(string, limit)
        string.length > limit ? string[0..limit-3] + '...' : string
      end

      def get_region(str)
        country, region = str.split('|')
        res = {country: country}
        res[:region] = region if region
        res
      end

      def get_regions(loc)
        loc.map {|str| get_region(str)}
      end

      def find_number(loc, type=:voice)
        res = get_region(loc)
        NumberPool.find_single_number(res, type)
      end


      def http_protected!(credentials)
        unless http_authorized?(credentials)
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def http_authorized?(credentials)
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == credentials
      end
    end

    before /^((?!((voice|sms)response)|reports|login|resetpassword|voicemails|progress-embed|campaign\-member\-count).)*$/ do
      login_required unless settings.environment == :test
    end

    before /(voice|sms)response/ do
      /(voice|sms)response\/(.*)/.match request.fullpath
      Crowdring.statsd.increment "#{$1}_received.count"
      service = $2.partition('?')[0]
      credentials = CompositeService.instance.credentials_for(service)
      http_protected! credentials if credentials
    end

    def respond(cur_service, request, response_type)
      response = AssignedPhoneNumber.handle(response_type, request)
      res = cur_service.build_response(request.to, response || [{cmd: :reject}])
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

    get '/campaign/result' do
      p "THANKS I GOT YOU"
    end

    get '/' do
      @campaigns = Campaign.all
      @unsubscribe_numbers = AssignedUnsubscribeVoiceNumber.all
      @unsubscribed_count = Ringer.unsubscribed.count
      @aggregate_campaigns = AggregateCampaign.all
      @all_fields = CsvField.all_fields

      haml :index
    end


    get '/unsubscribe_numbers/new' do
      @voice_numbers = NumberPool.available_summary

      haml :assign_unsubscribe_number
    end

    post '/unsubscribe_numbers/create' do
      unless params[:region]
        flash[:errors] = 'Please select a region'
        redirect to('/unsubscribe_numbers/new')
      end
      
      number = find_number(params[:region])
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

      redirect to("/")
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
      unless params[:campaign][:regions]
        flash[:errors] = "Must select at least one region"
        redirect to('campaign/new')
      end

      unless @title
        flash[:errors] = "Title can not be empty"
        redirect to('campaign/new')
      end

      regions = get_regions(params[:campaign][:regions])
      numbers = NumberPool.find_numbers(regions)
      @number_summary = numbers.zip(regions).map {|number, region| {number: number, region: region}}
      @sms_number = NumberPool.find_single_number(regions.first, :sms) || NumberPool.find_single_number({country: regions.first[:country]}, :sms)
      @goal = params[:campaign][:goal].to_i
      
      case params[:init_ask]
      when 'missed_call'
        haml :campaign_new_missed_call
      when 'sms_back'
        haml :campaign_new_sms_back
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
          FilteredMessage.create(constraints: [HasConstraint.create(tag: number.tag)], message_text: msg)
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

    get '/campaign/:id/voice_numbers/new' do
      @campaign = Campaign.get(params[:id])
      country = @campaign.voice_numbers.first.country.name
      @voice_numbers = NumberPool.available_summary.select {|n| n[:country] == country}

      haml :campaign_assign_voice_number
    end

    post '/campaign/:id/voice_numbers/create' do
      unless params[:region]
        flash[:errors] = 'Please select a region'
        redirect to("/campaign/#{params[:id]}/voice_numbers/new")
      end

      number = find_number(params[:region])
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
      message = params[:ask][:message]
      ask_type = params[:ask_type]
      unless ask_type
        flash[:errors] = "Ask type can not be empty"
        redirect to("/campaign/#{campaign.id}/asks/new")
      end
      ask_name = Ask.descendants.find{|a| a.typesym == ask_type.to_sym}
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
        flash[:errors] = "#{ask.all_errors.map(&:full_messages).reject(&:empty?).join('|')}"
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
      @campaign = Campaign.get(params[:id])
      @ask = Campaign.get(params[:id]).asks.get(params[:ask_id])

      haml :campaign_edit_ask
    end

    post '/campaign/:id/asks/:ask_id/update' do
      ask = Campaign.get(params[:id]).asks.get(params[:ask_id])
      params[:ask][:message] ||= nil
      if ask.update(params[:ask]) && ask.message.save
        flash[:notice] = "#{ask.title} has been updated."
        redirect to("/campaigns##{params[:id]}")
      else
        flash[:errors] = "#{ask.all_errors.map(&:full_messages).reject(&:empty?).join('|')}"
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

    post '/campaign/:id/ivrs/create' do
      ivr = params[:ivr]
      if ivr[:keyoption].empty?
        flash[:errors] = "Ivr must have at least one option"
        redirect to ("/campaigns##{campaign.id}")
      end

      campaign = Campaign.get(params[:id])
      new_ivr = Ivr.create(ivr)
      campaign.ivrs.last.deactivate unless campaign.ivrs.empty?
      campaign.ivrs << new_ivr
      campaign.save
      redirect to ("/campaigns##{campaign.id}")
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
        @basic_chart = HighChartsBuilder.basic_stats(@campaign)
        @sms_cost = SMSPrices.price_for(CompositeService.instance.service_for(:sms, @campaign.sms_number.raw_number), @campaign.sms_number)
        @all_fields = CsvField.all_fields

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
          params[:callback].present? ? jsonp(result, params[:callback]) : json(result)
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

    post '/campaign/:id/goal/update' do
      campaign = Campaign.get(params[:id])
      campaign.goal = params[:goal]
      if campaign.valid?
        campaign.save
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

    get '/export_csv' do
      @all_fields = CsvField.all_fields
      haml :campaign_export_csv
    end
    
    get '/csv' do
      option = params['option']
      case option
      when 'all'
        rings = Ring.all
        attachment("All-#{Time.now}.csv")
      else
        campaign = Campaign.get(option)
        attachment("#{campaign.title}-#{Time.now}.csv")
        rings = campaign.unique_rings
      end
      fields = params.key?('fields') ? params[:fields].keys.map {|id| CsvField.from_id id } : CsvField.default_fields
      CSV.generate do |csv|
        csv << fields.map {|f| f.display_name }
        rings.each {|ring| csv << fields.map {|f| ring.send(f.id) } }
      end
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

    post '/aggregate_campaigns/:name/destroy' do
      agg_campaign = AggregateCampaign.get(params[:name])
      if agg_campaign.destroy
        flash[:notice] = "Aggregate campaign #{params[:name]} has been removed"
      else
        flash[:errors] = "Failed to remove aggregate campaign #{params[:name]}."
      end
      redirect to('/')
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
