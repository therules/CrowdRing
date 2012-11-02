require 'tropo-provisioning'

module Crowdring
  class VoxeoRequest
    attr_reader :from, :to, :msg

    def initialize(request)
      @from = request.GET['callerID']
      @to = request.GET['calledID']
    end

    def callback?
      false
    end
  end

  class VoxeoService < TelephonyService
    supports :voice
    request_handler VoxeoRequest

    def initialize(app_id, username, password)
      @app_id = app_id
      @username = username
      @password = password
    end

    def build_response(from, commands)
      response = '<?xml version="1.0" encoding="UTF-8"?><callxml version="3.0">'
      response + commands.map do |c|
        case c[:cmd]
        when :reject
          '<reject />'
        when :record
          prompt = c[:prompt] || 'Please leave a message'
          "<answer><do><prompt value='#{prompt}'/><recordaudio value='#{c[:voicemail].filename}' format='audio/wav' /></do></answer>"
        end
      end.join('') + '</callxml>'
    end

    def numbers
      provisioning = TropoProvisioning.new(@username, @password)
      numbers = provisioning.addresses(@app_id).select {|a| a.type == 'number' }
      numbers.map(&:number)
    end
  end
end