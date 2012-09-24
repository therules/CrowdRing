require 'rspec'
require 'rack/test'
require 'capybara'
require 'capybara/dsl'


ENV['RACK_ENV'] ||= 'test'
ENV['PUSHER_APP_ID'] = 'app_id'
ENV['PUSHER_KEY'] = 'key'
ENV['PUSHER_SECRET'] = 'secret'
ENV['USERNAME'] = 'admin'
ENV['PASSWORD'] = 'admin'
require 'crowdring'

Capybara.app = Crowdring::Server

RSpec.configure do |config|
  config.include Capybara::DSL
end

include Rack::Test::Methods

def app
  Crowdring::Server
end

def login
  authorize 'admin', 'admin'
end