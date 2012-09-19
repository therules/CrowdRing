require 'crowdring'
require 'rspec'
require 'rack/test'

ENV['RACK_ENV'] ||= 'test'

module Crowdring
  describe Server do
    include Rack::Test::Methods

    def app
      Crowdring::Server
    end

    before(:each) do
      DataMapper.auto_migrate!
      @number = '+11231231234'
    end

    it 'should return a valid response for /' do
      get '/'
      last_response.ok?.should be_true
    end

    it 'should create a new campaign given a valid title and number' do
      post '/campaign/create', {'title' => 'title', 'phone_number' => @number}
      Campaign.get(@number).should_not be_nil
    end

    it 'should redirect to campaign view on successful campaign creation' do
      post '/campaign/create', {'title' => 'title', 'phone_number' => @number}
      last_response.should be_redirect
      last_response.location.should include("/##{@number}")
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
      last_response.location.should include("/campaign/new")
    end




  end
end