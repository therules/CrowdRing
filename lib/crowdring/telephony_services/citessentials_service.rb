require 'eventmachine'

module Crowdring
  class CitessentialsRequest
    attr_reader :from, :to, :message

    def initialize(request)
      @from = request.GET['from']
      @to = request.GET['to']
      @message = request.GET['text']
    end

  end

  class CitessentialsService < TelephonyService
    supports :sms
    request_handler CitessentialsRequest
    @@mt_id = 0

    def initialize(username, password)
      @config = {
      :host => '0.0.0.0',
      :port => 6000,
      :system_id => 'hugo',
      :password => 'ggoohu',
      :system_type => '', 
      :interface_version => 52,
      :source_ton  => 0,
      :source_npi => 1,
      :destination_ton => 1,
      :destination_npi => 1,
      :source_address_range => '',
      :destination_address_range => '',
      :enquire_link_delay_secs => 10
    }
      EventMachine.run do
        @@tx = EventMachine.connect(
          @config[:host],
          @config[:port],
          Smpp::Transceiver,
          @config, 
          self
          )

        @redis = EM::Hiredis.connect
        
        pop_message = lambda do 
          @redis.loop  'message:send:queue' do |message|
            if message
              message = Yajl::Parser.parse(message, check_utl8: true)
              @@tx.send_mt(message[:from], message[:to], message[:msg])
              p "#{message}"
            end
            EM.next_tick &pop_message
          end
        end
      end
    end

    def numbers
      ['+13121111111']
    end

    def build_response(from, commands)
      ''
    end

    def send_sms(params)
      @redis.rpush 'message:send:queue', params
      p params
    end
  end
end




