require 'rspec'
require 'rack/test'
require 'pusher-fake'

ENV['RACK_ENV'] ||= 'test'
ENV['PUSHER_APP_ID'] = 'app_id'
ENV['PUSHER_KEY'] = 'key'
ENV['PUSHER_SECRET'] = 'secret'

require 'crowdring'


module Crowdring
  describe Server do
    include Rack::Test::Methods

    def app
      Crowdring::Server
    end

    before(:all) do
      PusherFake.configure do |configuration|
        configuration.app_id = Pusher.app_id
        configuration.key    = Pusher.key
        configuration.secret = Pusher.secret
      end
      
      Pusher.host = PusherFake.configuration.web_host
      Pusher.port = PusherFake.configuration.web_port

      fork { PusherFake::Server.start }.tap do |id|
        at_exit { Process.kill("KILL", id) }
      end
    end

    before(:each) do
      Server.service_handler.reset
      DataMapper.auto_migrate!
      @number = '+11231231234'
      @number2 = '+22222222222'
      @number3 = '+33333333333'
    end

    after(:all) do
      PusherFake::Channel.reset
      Server.service_handler.reset
      DataMapper.auto_migrate!
    end

    it 'should return a valid response for /' do
      get '/'
      last_response.should be_ok
    end

    describe 'campaign creation/deletion' do
      it 'should create a new campaign given a valid title and number' do
        post '/campaign/create', {'title' => 'title', 'phone_number' => @number}
        Campaign.get(@number).should_not be_nil
      end

      it 'should redirect to campaign view on successful campaign creation' do
        post '/campaign/create', {'title' => 'title', 'phone_number' => @number}
        last_response.should be_redirect
        last_response.location.should match("/##{Regexp.quote(@number)}$")
      end

      it 'should not create a campaign when given a empty title' do
        post '/campaign/create', {'title' => '', 'phone_number' => @number}
        Campaign.get(@number).should be_nil
      end

      it 'should not create a campaign when given an extremely long title' do
        post '/campaign/create', {'title' => 'foobar'*100, 'phone_number' => @number}
        Campaign.get(@number).should be_nil
      end

      it 'should not create a campaign when given an invalid number' do
        post '/campaign/create', {'title' => 'title', 'phone_number' => 'foobar'}
        Campaign.get('foobar').should be_nil
      end

      it 'should remain on campaign creation page when fails to create a campaign' do
        post '/campaign/create', {'title' => 'title', 'phone_number' => 'foobar'}
        last_response.should be_redirect
        last_response.location.should match('campaign/new$')
      end

      it 'should be able to destroy a campaign' do
        Campaign.create(title: 'title', phone_number: @number)
        post '/campaign/destroy', {'phone_number' => @number}
        Campaign.get(@number).should be_nil
      end

      it 'should destroy supporters when destroying a campaign' do
        Campaign.create(title: 'title', phone_number: @number)
        Campaign.first.supporters.create(phone_number: @number)
        post '/campaign/destroy', {'phone_number' => @number}
        Supporter.first.should be_nil
      end

      it 'should redirect back to / after destroying a campaign' do
        Campaign.create(title: 'title', phone_number: @number)
        post '/campaign/destroy', {'phone_number' => @number}
        last_response.should be_redirect
        last_response.location.should match('/$')
      end
    end

    describe 'campaign fetching' do
      it 'should successfully fetch a campaign at campaign/number' do
        Campaign.create(title: 'title', phone_number: @number)
        get "/campaign/#{@number}"
        last_response.should be_ok
      end

      it 'should redirect back to / on trying to fetch a non-existant campaign' do
        get "/campaign/badnumber"
        last_response.status.should eq(404)
      end
    end

    describe 'voice/sms response forwarding' do
      before(:each) do
        @campaign = Campaign.new(phone_number: @number, title: @number)
        @campaign.save
        @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
        @fooservice = double('fooservice', build_response: 'fooResponse',
            supports_outgoing?: true,
            transform_request: @fooresponse,
            numbers: [@number],
            send_sms: nil)
        @barservice = double('barservice', build_response: 'barResponse',
            supports_outgoing?: false,
            transform_request: @fooresponse,
            numbers: [@number3],
            send_sms: nil)
      end

      it 'should forward a POST voice request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: @campaign.introductory_message)

        Server.service_handler.add('foo', @fooservice)
        post '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an POST sms request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: @campaign.introductory_message)

        Server.service_handler.add('foo', @fooservice)
        post '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward a GET voice request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: @campaign.introductory_message)

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an GET sms request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: @campaign.introductory_message)

        Server.service_handler.add('foo', @fooservice)
        get '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should respond on the sending service and reply on the default service if the sending service doesnt support outgoing' do
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: @campaign.introductory_message)
        @fooservice.should_not_receive(:build_response)
        @barservice.should_receive(:build_response).once
        @barservice.should_not_receive(:send_sms)

        Server.service_handler.add('foo', @fooservice, default: true)
        Server.service_handler.add('bar', @barservice)
        get '/smsresponse/bar'
        last_response.should be_ok
        last_response.body.should eq('barResponse')
      end

      it 'should respond without error to a number not currently associated with a campaign' do
        @fooresponse.stub(to: @number3)
        @fooservice.should_receive(:build_response).once
        @fooservice.should_not_receive(:send_sms)

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should handle a callback by informing the corresponding service' do
        @fooresponse.stub(callback?: true)
        @fooservice.stub(process_callback: 'foocallback')
        @fooservice.should_receive(:process_callback).once
        @fooservice.should_not_receive(:build_response)
        @fooservice.should_not_receive(:send_sms)

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('foocallback')
      end
    end

    describe 'message broadcasting' do
      it 'should broadcast a message to all supporters of a campaign' do
        sent_to = []
        campaign = Campaign.new(phone_number: @number, title: @number)
        campaign.save
        fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
        fooservice = double('fooservice', build_response: 'fooResponse',
            supports_outgoing?: true,
            transform_request: fooresponse,
            numbers: [@number])
        fooservice.stub!(:send_sms) {|params| sent_to << params[:to]}
        fooservice.should_receive(:send_sms).twice

        campaign.supporters.create(phone_number: @number2)
        campaign.supporters.create(phone_number: @number3)
        Server.service_handler.add('foo', fooservice)
        post '/broadcast', {phone_number: @number, message: 'message'}
        sent_to.should include(@number2)
        sent_to.should include(@number3)
      end

      it 'should redirect to the campaign page after broadcasting' do
        campaign = Campaign.new(phone_number: @number, title: @number)
        campaign.save
        fooservice = double('fooservice')

        Server.service_handler.add('foo', fooservice)
        post '/broadcast', {phone_number: @number, message: 'message'}
        last_response.should be_redirect
        last_response.location.should match("/##{Regexp.quote(@number)}$")
      end
    end
  end
end
