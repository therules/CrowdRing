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
      :host => '127.0.0.1',
      :port => 6000,
      :system_id => username,
      :password => password,
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

    
    end

    def numbers
      ['+13121111111']
    end

    def build_response(from, commands)
      ''
    end

    def send_sms(params)
      EventMachine::run do
        @@tx = EventMachine::connect(
          @config[:host],
          @config[:port],
          Smpp::Transceiver,
          @config, 
          self
          )
        @@mt_id += 1
        @@tx.send_mt(@@mt_id, params[:from], params[:to], params[:msg])
        p params
      end
      EventMachine::stop
    end
  end
end




