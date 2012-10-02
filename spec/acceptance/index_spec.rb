require File.dirname(__FILE__) + '/spec_helper'

require 'crowdring/logging_service'

describe 'Filtering supporters', type: :request, js: true do

  before(:all) do
    @number = '+11111111111'
    @logging_service = Crowdring::LoggingService.new([@number])
    Crowdring::Server.service_handler.add('logging', @logging_service)
  end

  before(:each) do
    Capybara.app_host = 'http://localhost:5000'

    DataMapper.auto_migrate!
    @number2 = '+22222222222'
    @number3 = '+33333333333'
    @campaign = Crowdring::Campaign.create(title: 'title', introductory_message: 'intro message')
    @campaign.assigned_phone_numbers.create(phone_number: @number)
    page.driver.browser.authorize 'admin', 'admin'
  end

  it 'Filtering supporters based on who has joined since the most recent broadcast' do
    origSupporter = Crowdring::Supporter.create(phone_number: @number2)
    @campaign.memberships.create(supporter: origSupporter, created_at: DateTime.now-2)
    @campaign.most_recent_broadcast = DateTime.now - 1
    newSupporter = @campaign.supporters.create(phone_number: @number3)
   
    visit "/campaign/#{@campaign.id}"
    page.find("label[for=new1]").text.should match('1')

    within('#broadcast') do
      choose('new1')
      click_button('broadcastbutton')
    end

    @logging_service.last_broadcast[:to_numbers].should eq([@number3])
    Crowdring::Campaign.get(@campaign.id).new_memberships.count.should eq(0)
  end
end
