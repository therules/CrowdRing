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
          here
          response.addHangup(reason: 'busy')
          dial = response.addDial(callerId: from)
          dial.addNumber(c[:to])
          digit = response.addGetDigits(action: '/', method: 'GET', redirect: false)
          digit.addSpeak("#{c[:text]}")
          response.addSpeak('No input received')
        when :record
          response.addSpeak("#{c[:promt]}")
          response.addRecord(action: "#{c[:voicemail].plivo_callback}", callbackUrl: "#{c[:voicemail].plivo_callback}")
        end
      end
      response
    end


    def numbers
      @rest_api.get_numbers[1]['objects'].map {|o| o['number']}
    end
  end

end

# "GET /campaign/result?Digits=111&Direction=inbound&From=12125420421&CallerName=12125420421&BillRate=0.00900&To=13122815301&CallUUID=828bc1ac-59c8-11e2-84e3-791bc7030761&Event=Redirect HTTP/1.1" 302 - 0.0011