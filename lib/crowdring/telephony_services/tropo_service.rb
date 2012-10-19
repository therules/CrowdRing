require 'tropo-webapi-ruby'
require 'net/http'
require 'tropo-provisioning'

module Crowdring
  class TropoRequest
    attr_reader :from, :to, :msg

    def initialize(request)
      session = Tropo::Generator.parse(request.body.read).session
      @is_callback = session.parameters?
      if @is_callback
        @from = session.parameters.from
        @to = session.parameters.to
        @msg = session.parameters.msg
      else
        @from = session.from.name
        @to = session.to.name
      end
    end

    def callback?
      @is_callback
    end
  end

  class TropoService < TelephonyService
    supports :voice, :sms
    request_handler TropoRequest

    def initialize(msg_token, app_id, username, password)
      @msg_token = msg_token
      @app_id = app_id
      @username = username
      @password = password
    end

    def process_callback(request)
      build_response(request.from, [{cmd: :sendsms, to: request.to, msg: request.msg}])
    end

    def build_response(from, commands)
      response = Tropo::Generator.new do
        commands.each do |c|
          case c[:cmd]
          when :sendsms
            message(to: c[:to], network: 'SMS', channel: 'TEXT') do
              say c[:msg]
            end
          when :reject
            reject
          end
        end
      end
      response.response
    end

    def numbers
      provisioning = TropoProvisioning.new(@username, @password)
      numbers = provisioning.addresses(@app_id).select {|a| a.type == 'number' && a.smsEnabled }
      numbers.map(&:number)
    end

    def send_sms(params)
      uri = URI('http://api.tropo.com/1.0/sessions')
      params = { action: 'create', token: @msg_token, from: params[:from], to: params[:to], msg: params[:msg] }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
    end

    def broadcast(from, msg, to_numbers)
      params = {msg_token: @msg_token, app_id: @app_id,
                username: @username, password: @password}
      Resque.enqueue(TropoBatchSendSms, params, from, msg, to_numbers)
    end
  end
end