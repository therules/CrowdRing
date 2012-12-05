require File.dirname(__FILE__) + '/spec_helper'

module Crowdring
  describe Server do
    include Rack::Test::Methods

    def app
      Crowdring::Server
    end

    before(:each) do
      Server.service_handler.reset
      DataMapper.auto_migrate!
      @number = '+18001231234'
      @numbers = [@number]
      @number2 = '+18002222222'
      @number3 = '+18003333333'
      @intro_response = Message.create(default_message:'default')
    end

    after(:all) do
      Server.service_handler.reset
      DataMapper.auto_migrate!
    end

    describe 'campaign creation/deletion' do
      it 'should create a new campaign given a valid title, number, and introductory message' do
        post '/campaign/create/missed_call', {'campaign' => {'title' => 'title', 'voice_numbers' => [{phone_number: @number}]}}
        Campaign.first(title: 'title').should_not be_nil
      end

      it 'should redirect to campaign view on successful campaign creation' do
        post '/campaign/create/missed_call', {'campaign' => {'title' => 'title', 'voice_numbers' => [{phone_number: @number}]}}
        last_response.should be_redirect
        last_response.location.should match("campaigns##{Regexp.quote(Campaign.first(title: 'title').id.to_s)}$")
      end

      it 'should not create a campaign when given a empty title' do
        post '/campaign/create/missed_call', {'campaign' => {'title' => ''}}
        Campaign.first(title: 'title').should be_nil
      end

      it 'should not create a campaign when given an extremely long title' do
        post '/campaign/create/missed_call', {'campaign' => {'title' => 'foobar'*100}}
        Campaign.first(title: 'foobar'*100).should be_nil
      end

      it 'should remain on campaign creation page when fails to create a campaign' do
        post '/campaign/create/missed_call', {'campaign' => {'title' => ''}}
        last_response.should be_redirect
        last_response.location.should match('campaign/new$')
      end

      it 'should be able to destroy a campaign' do
        c = Campaign.create(title: 'title')
        post "/campaign/#{c.id}/destroy"
        Campaign.get(c.id).should be_nil
      end

      it 'should redirect back to / after destroying a campaign' do
        c = Campaign.create(title: 'title', voice_numbers: [{phone_number: @number}])
        post "/campaign/#{c.id}/destroy"
        last_response.should be_redirect
        last_response.location.should match('/$')
      end
    end

    describe 'campaign fetching' do
      it 'should successfully fetch a campaign at campaign/id' , focus: true do
        CompositeService.instance.add('foo', LoggingService.new(@numbers))
        c = Campaign.create(title: 'title', voice_numbers: [{phone_number: @number, description: 'desc'}], sms_number: @number)
        get "/campaign/#{c.id}"
        last_response.should be_ok
        CompositeService.instance.reset
      end

      it 'should redirect back to / on trying to fetch a non-existant campaign' do
        get "/campaign/badnumber"
        last_response.status.should eq(404)
      end
    end

    describe 'voice/sms response forwarding' do
      before(:each) do
        @campaign = Campaign.create(title: @number, voice_numbers: [{phone_number: @number, description: 'desc'}], sms_number: @number)
        @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number, message: 'message')
        @fooservice = double('fooservice', build_response: 'fooResponse',
            sms?: true,
            transform_request: @fooresponse,
            numbers: [@number],
            send_sms: nil)
        @barservice = double('barservice', build_response: 'barResponse',
            sms?: false,
            transform_request: @fooresponse,
            numbers: [@number3],
            send_sms: nil)
      end

      it 'should forward a POST voice request to the registered service' do
        @fooservice.should_receive(:build_response).once

        Server.service_handler.add('foo', @fooservice)
        post '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an POST sms request to the registered service' do
        @fooservice.should_receive(:build_response).once

        Server.service_handler.add('foo', @fooservice)
        post '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward a GET voice request to the registered service' do
        @fooservice.should_receive(:build_response).once

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an GET sms request to the registered service' do
        @fooservice.should_receive(:build_response).once

        Server.service_handler.add('foo', @fooservice)
        get '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should respond without error to a number not currently associated with a campaign' do
        @fooresponse.stub(to: @number3)
        @fooservice.should_receive(:build_response).once

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

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('foocallback')
      end
    end

    describe 'message broadcasting' do
      before(:each) do
        @sent_to = []
        @campaign = Campaign.create(title: @number, voice_numbers: [{phone_number: @number, description: 'desc'}], sms_number: @number)
        fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
        fooservice = double('fooservice', build_response: 'fooResponse',
            sms?: true,
            transform_request: fooresponse,
            numbers: [@number])
        fooservice.stub(:broadcast) {|_,_,to_nums| @sent_to.concat to_nums}
        Server.service_handler.add('foo', fooservice)
      end


      it 'should broadcast a message to all ringers of a campaign' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
        
        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: 'all'}
        @sent_to.should include(@number2)
        @sent_to.should include(@number3)
      end

      it 'should redirect to the campaign page after broadcasting' do
        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: 'all'}
        last_response.should be_redirect
        last_response.location.should match("campaigns##{Regexp.quote(@campaign.id.to_s)}$")
      end
    end

    describe 'campaign exporting' do
      before(:each) do
        @campaign = Campaign.create(title: @number, voice_numbers: [{phone_number: @number, description: 'desc'}], sms_number: @number2)
      end

      it 'should return a csv file' do
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: {phone_number: 'yes', created_at: 'yes'}}
        last_response.header['Content-Disposition'].should match('attachment')
        last_response.header['Content-Disposition'].should match('\.csv')
      end

      def verify_csv(csvString, memberships, fields=[])
        csv_ringers = CSV.parse(csvString)
        headers = csv_ringers[0]
        fields.zip(headers).each {|f, h| h.should eq(CsvField.from_id(f).display_name) }
        csv_ringers[1..-1].zip(memberships).each do |csvRinger, origRinger|
          fields.each_with_index {|field, idx| csvRinger[idx].should eq(origRinger.send(field).to_s) }
        end
      end

      it 'should export all of the ringers numbers and support dates' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
        
        fields = {phone_number: 'yes', created_at: 'yes'}
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: fields}
        verify_csv(last_response.body, @campaign.unique_rings, fields.keys)
      end
 
      it 'should export the ringers country codes' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
         
        fields = {country_code: 'yes'}
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: fields}
        verify_csv(last_response.body, @campaign.ringers, fields.keys)
      end

      it 'should export the ringers area codes' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
        
        fields = {area_code: 'yes'}
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: fields}
        verify_csv(last_response.body, @campaign.ringers, fields.keys)
      end
    end
    describe 'campaign and asks' do
      include Rack::Test::Methods

      before(:each) do
        Crowdring::Server.service_handler.reset
        DataMapper.auto_migrate!
        @voice_num1 = '+18001111111'
        @voice_num2 = '+18002222222'
        @voice_num3 = '+18003333333'
        @sms_num1 = '+18009999999'
        @sms_num2 = '+18008888888'
        @number4 = '+18004444444'
        @number5 = '+18005555555'

        @c = Crowdring::Campaign.create(title: 'test', voice_numbers: [{phone_number: @voice_num1, description: 'num1'}], sms_number: @sms_num1)

        @fooservice = double('fooservice', build_response: 'fooResponse',
          sms?: true,
          transform_request: @fooresponse,
          numbers: [@voice_num1, @sms_num1],
          send_sms: nil)
        Crowdring::CompositeService.instance.reset
        Crowdring::CompositeService.instance.add('foo', @fooservice)
      end

      it 'should be able to add new ask after campaign creation' do
        params = {'ask_type' => 'text_ask', 'trigger_by' => 'user','ask' => { 'title' => 'title', 'message' => {'default_message' => 'hello'}}}
        post "/campaign/#{@c.id}/asks/create" ,params

        Crowdring::Campaign.first.asks.count.should eq(2)
      end

      it 'should be able to lauch new ask to whole ringers' do
        c2 = Crowdring::Campaign.create(title: 'c2', voice_numbers:[{phone_number: @voice_num2, description: 'num2'}], sms_number:@sms_num2)
        r1 = Crowdring::Ringer.create(phone_number: @number4)
        r2 = Crowdring::Ringer.create(phone_number: @number5)

        @c.voice_numbers.first.ring(r1)
        c2.voice_numbers.first.ring(r2)

        message = Crowdring::Message.create(default_message: 'Blah')
        new_ask = Crowdring::SendSMSAsk.create(title: 'sendsms', message: message)
        @c.asks << new_ask
        @c.save
        post "/campaign/#{@c.id}/asks/#{new_ask.id}/trigger"
        r1.reload
        r2.reload

        r1.tags.should include(Crowdring::Tag.from_str("ask_recipient:#{new_ask.id}"))
        r2.tags.should include(Crowdring::Tag.from_str("ask_recipient:#{new_ask.id}"))
      end

      it 'should be able to remove ask added after campaign creation'  do
        message = Crowdring::Message.create(default_message: 'Blah')
        new_ask = Crowdring::SendSMSAsk.create(title: 'Support the SpiderMan please', message: message)
        @c.asks << new_ask
        @c.save
        post "/campaign/#{@c.id}/asks/#{new_ask.id}/destroy"
        
        @c.asks.count.should eq(1)
      end

      it 'should be able to edit ask title' do
        message = Crowdring::Message.create(default_message: 'Blah')
        new_ask = Crowdring::SendSMSAsk.create(title: 'Do you like pre-open bananas?', message: message)
        @c.asks << new_ask
        @c.save
        
        params = {'ask' => {'title' => 'Do not open bananas!'}}
        post "/campaign/#{@c.id}/asks/#{new_ask.id}/update", params

        new_ask.reload
        new_ask.title.should eq('Do not open bananas!')
      end

      it 'should be able to edit ask message' , focus: true do
        message = Crowdring::Message.create(default_message: 'Blah')
        new_ask = Crowdring::SendSMSAsk.create(title: 'Do you like pre-open bananas?', message: message)
        @c.asks << new_ask
        @c.save
        
        params = {'ask' => {'title' => 'Do you like pre-open bananas?', 'message' => {'default_message' => 'BlahBlah'}}}
        post "/campaign/#{@c.id}/asks/#{new_ask.id}/update", params

        new_ask.reload
        new_ask.message.default_message.should eq('BlahBlah')
      end
    end
  end
end
