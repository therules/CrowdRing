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
        post '/campaign/create', {'campaign' => {'title' => 'title'}}
        Campaign.first(title: 'title').should_not be_nil
      end

      it 'should redirect to campaign view on successful campaign creation' do
        post '/campaign/create', {'campaign' => {'title' => 'title'}}
        last_response.should be_redirect
        last_response.location.should match("campaigns##{Regexp.quote(Campaign.first(title: 'title').id.to_s)}$")
      end

      it 'should not create a campaign when given a empty title' do
        post '/campaign/create', {'campaign' => {'title' => ''}}
        Campaign.first(title: 'title').should be_nil
      end

      it 'should not create a campaign when given an extremely long title' do
        post '/campaign/create', {'campaign' => {'title' => 'foobar'*100}}
        Campaign.first(title: 'foobar'*100).should be_nil
      end

      it 'should remain on campaign creation page when fails to create a campaign' do
        post '/campaign/create', {'campaign' => {'title' => ''}}
        last_response.should be_redirect
        last_response.location.should match('campaign/new$')
      end

      it 'should be able to destroy a campaign' do
        c = Campaign.create(title: 'title', message: @intro_response)
        post "/campaign/#{c.id}/destroy"
        Campaign.get(c.id).should be_nil
      end

      it 'should redirect back to / after destroying a campaign' do
        c = Campaign.create(title: 'title', message: @intro_response)
        post "/campaign/#{c.id}/destroy"
        last_response.should be_redirect
        last_response.location.should match('/$')
      end
    end

    describe 'campaign fetching' do
      it 'should successfully fetch a campaign at campaign/id' do
        c = Campaign.create(title: 'title', message: @intro_response)
        get "/campaign/#{c.id}"
        last_response.should be_ok
      end

      it 'should redirect back to / on trying to fetch a non-existant campaign' do
        get "/campaign/badnumber"
        last_response.status.should eq(404)
      end
    end

    describe 'voice/sms response forwarding' do
      before(:each) do
        @campaign = Campaign.create(title: @number, message: @intro_response, voice_numbers: [{phone_number: @number, description: 'desc'}], sms_number: @number)
        @fooresponse = double('fooresponse', callback?: false, from: @number2, to: @number)
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
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'default')

        Server.service_handler.add('foo', @fooservice)
        post '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an POST sms request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'default')

        Server.service_handler.add('foo', @fooservice)
        post '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward a GET voice request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'default')

        Server.service_handler.add('foo', @fooservice)
        get '/voiceresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should forward an GET sms request to the registered service' do
        @fooservice.should_receive(:build_response).once
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'default')

        Server.service_handler.add('foo', @fooservice)
        get '/smsresponse/foo'
        last_response.should be_ok
        last_response.body.should eq('fooResponse')
      end

      it 'should respond on the sending service and reply on the default service if the sending service doesnt support outgoing' do
        @fooservice.should_receive(:send_sms).once.with(from: @number, to: @number2, msg: 'default')
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
        @campaign.sms_number.ring(r1)
        @campaign.sms_number.ring(r2)
        
        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: 'all'}
        @sent_to.should include(@number2)
        @sent_to.should include(@number3)
      end

      it 'should redirect to the campaign page after broadcasting' do
        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: 'all'}
        last_response.should be_redirect
        last_response.location.should match("campaigns##{Regexp.quote(@campaign.id.to_s)}$")
      end

      it 'should broadcast only to the new ringers of a campaign' do
        ringer = Crowdring::Ringer.create(phone_number: @number2)
        Crowdring::Ring.create(ringer: ringer, created_at: DateTime.now-2)

        @campaign.most_recent_broadcast = DateTime.now - 1
        @campaign.save
        newringer = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.sms_number.ring(newringer)

        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: "after:#{@campaign.most_recent_broadcast}"}
        @sent_to.should eq([@number3])
      end

      it 'should not have any new ringers after a broadcast' do
        ringer = Crowdring::Ringer.create(phone_number: @number2)
        Crowdring::Ring.create(ringer: ringer, created_at: DateTime.now-2)

        @campaign.most_recent_broadcast = DateTime.now - 1
        @campaign.save
        newringer = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.sms_number.ring(newringer)

        post "/campaign/#{@campaign.id}/broadcast", {message: 'message', filter: "after:#{@campaign.most_recent_broadcast}"}
        Campaign.get(@campaign.id).new_rings.should be_empty
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

      it 'should export only the new ringers numbers and support dates' do
        @campaign.most_recent_broadcast = DateTime.now - 1
        @campaign.save
        @campaign.ringers.create(phone_number: @number3)

        get "/campaign/#{@campaign.id}/csv", {filter: "after:#{@campaign.most_recent_broadcast}"}
        verify_csv(last_response.body, @campaign.new_rings)
      end

      it 'should export the ringers country codes' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
         
        fields = {country_code: 'yes'}
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: fields}
        verify_csv(last_response.body, @campaign.new_rings, fields.keys)
      end

      it 'should export the ringers area codes' do
        r1 = Crowdring::Ringer.create(phone_number: @number2)
        r2 = Crowdring::Ringer.create(phone_number: @number3)
        @campaign.voice_numbers.first.ring(r1)
        @campaign.voice_numbers.first.ring(r2)
        
        fields = {area_code: 'yes'}
        get "/campaign/#{@campaign.id}/csv", {filter: 'all', fields: fields}
        verify_csv(last_response.body, @campaign.new_rings, fields.keys)
      end
    end
  end
end
