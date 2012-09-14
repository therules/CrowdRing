require 'tropo-webapi-ruby'

module Crowdring
  class TropoService 

    def initialize(msg_token, numbers)
      @msg_token = msg_token
      @numbers = numbers
    end

    def is_callback?(request)
      params = Tropo::Generator.parse request.body.read
      request.body.rewind 
      params.session.exists? :parameters
    end

    def process_callback(request)
      params = Tropo::Generator.parse(request.body.read).session.parameters
      request.body.rewind 
      build_response(params[:from], to: params[:to], msg: params[:msg])
    end

    def extract_params(request)
      params = Tropo::Generator.parse request.body.read
      request.body.rewind 
      {from: params.session.from.name, to: params.session.to.name}
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
      @numbers
    end

    def send_sms(params)
      uri = URI('http://api.tropo.com/1.0/sessions')
      params = { action: 'create', token: @msg_token, from: params[:from], to: params[:to], msg: params[:msg] }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
    end
  end
end