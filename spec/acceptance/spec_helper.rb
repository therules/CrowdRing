require File.dirname(__FILE__) + '/../spec_helper'

require 'capybara'
require 'capybara/dsl'

Capybara.app = Crowdring::Server

RSpec.configure do |config|
  config.include Capybara::DSL
end

include Rack::Test::Methods

def app
  Crowdring::Server
end
