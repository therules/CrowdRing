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
      response = '<?xml version="1.0" encoding="UTF-8"?><Response>'
      response + commands.map do |c|
        case c[:cmd]
        when :reject
          build_ivr
        when :record
          "<Speak>#{c[:prompt]}</Speak><Record action='#{c[:voicemail].plivo_callback}' callbackUrl='#{c[:voicemail].plivo_callback}'/>"
        end
      end.join('') + '</Response>'
    end

   def build_ivr
    response = '<GetDigits action="#{ENV['SERVER_NAME']}/campaign/result" method="GET"><Speak>Please enter your number</Speak></GetDigits>'
   end 

    def numbers
      @rest_api.get_numbers[1]['objects'].map {|o| o['number']}
    end
  end

end