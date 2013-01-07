require 'eventmachine'

module Crowdring
  class CitessentialsRequest
    attr_reader :from, :to, :message

    def initialize(request)
      @from = request.GET['from']
      @to = request.GET['to']
      @message = request.GET['text']
    end

    def callback?
      false
    end

  end

  class CitessentialsService < TelephonyService
    supports :sms
    request_handler CitessentialsRequest
    @@mt_id = 0

    def initialize(username, password)
      @message_queue = Queue.new
      @config = {
        :host => '54.243.246.177',
        :port => 10109,
        :system_id => username,
        :password => password,
        :system_type => '3.4', 
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
      ['+19705574941']
    end

    def build_response(from, commands)
      ''
    end

    def send_sms(params)
      @message_queue << params
      @@tx = EventMachine.connect(
          @config[:host],
          @config[:port],
          Smpp::Transceiver,
          @config, 
          self
          )
        @@mt_id += 1

      pop_message = Proc.new do |message|
        @@mt_id += 1
        if message[:msg] <= 160
          @@tx.send_mt(@@mt_id, message[:from], message[:to], message[:msg])
        else
          @@tx.send_concat_mt(@@mt_id, message[:from], message[:to], message[:msg])
        end
        @message_queue.pop & pop_message
      end
    end

  end
end




