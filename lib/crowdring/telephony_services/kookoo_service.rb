require 'builder'
require 'net/http'

module Crowdring
  class KooKooRequest
    attr_reader :from, :to

    def initialize(request, to)
      @to = to
      @from = request.GET['cid']
    end

    def callback?
      false
    end
  end

  class KooKooService < TelephonyService
    supports :voice, :sms
    request_handler(KooKooRequest) {|inst| [inst.numbers.first]}

    def initialize(api_key)
      @api_key = api_key
      @number = ['+911130715351']
    end

    def build_response(from, commands)
      builder = Builder::XmlMarkup.new(indent: 2)
      builder.response do |r|
        commands.each do |c|
          case c[:cmd]
          when :sendsms
            r.sendsms c[:msg], to: c[:to]
          when :reject
            r.hangup
          end
        end
      end
    end

    def numbers
      @number
    end

    def send_sms(params)
      uri = URI('http://www.kookoo.in/outbound/outbound_sms.php')
      params = { message: params[:msg], phone_no: params[:to], api_key: @api_key }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
    end
  end
end