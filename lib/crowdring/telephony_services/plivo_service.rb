require 'plivo'

module Crowdring
  class PlivoRequest
    attr_reader :from, :to, :message

    def initialize(request)
      @from = request.POST['From']
      @to = request.POST['To']
    end

    def callback?
      false
    end
  end

  class PlivoService < TelephonyService
    supports :voice
    request_handler PlivoRequest

    def initialize(auth_id, auth_token)
      @rest_api = Plivo::RestAPI.new(auth_id, auth_token)
    end

    def build_response(from, commands)
      response = Plivo::Response.new
      commands.map do |c|
        case c[:cmd]
        when :reject
          response.addHangup(reason: 'busy')
        when :ivr
          c_id = c[:campaign_id]
          params = {to: "#{format_number(c[:to])}", from: "#{from}", 
                    answer_url: "#{ENV['SERVER_NAME']}/ivrs/plivo_hangup", 
                    answer_method: 'GET',
                    hangup_url: "#{ENV['SERVER_NAME']}/ivrs/#{c_id}/trigger",
                    hangup_method: 'POST'}
          res = @rest_api.make_call(params)
          response.addHangup(reason: 'busy')
        when :record
          response.addSpeak("#{c[:prompt]}")
          response.addRecord(action: "#{c[:voicemail].plivo_callback}", callbackUrl: "#{c[:voicemail].plivo_callback}")
        end
      end
      response.to_xml()
    end


    def numbers
      @rest_api.get_numbers[1]['objects'].map {|o| o['number']}
    end
  end
end

