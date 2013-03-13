require 'rspec'
require 'rack/test'
require 'pusher-fake'
require 'fakeweb'

require 'factory_girl'
require 'dm-rspec'
require 'factories'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include DataMapper::Matchers
  config.order = 'random'
end

ENV['RACK_ENV'] ||= 'test'
ENV['PUSHER_APP_ID'] = 'app_id'
ENV['PUSHER_KEY'] = 'key'
ENV['PUSHER_SECRET'] = 'secret'
ENV['USERNAME'] = 'admin'
ENV['PASSWORD'] = 'admin'

require 'crowdring'


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