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

      # Start the fake web server.
      fork { PusherFake::Server.start }.tap do |id|
        at_exit { Process.kill("KILL", id) }
      end
    end

    before(:each) do
      DataMapper.auto_migrate!
      @number = '+11231231234'
    end

    after(:all) do
      PusherFake::Channel.reset
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
  end
end
