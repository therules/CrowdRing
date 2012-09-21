require 'crowdring/twilio_service'
require 'crowdring/kookoo_service'

module Crowdring
  class TwilioBatchSendSms
    @queue = :send_sms

    def self.perform(params, from, msg, to_numbers)
      service = TwilioService.new(params['account_sid'], params['auth_token'])
      to_numbers.each do |to|
        begin
          service.send_sms from: from, to: to, msg: msg 
        rescue Twilio::REST::RequestError => e
          p "Send sms failed with RequestError: #{e.message}"
        rescue Twilio::REST::ServerError => e
          p "Send sms failed with ServerError: #{e.message}"
        end
      end
    end
  end

  class TropoBatchSendSms
    @queue = :send_sms

    def self.perform(params, from, msg, to_numbers)
      service = TropoService.new(params['msg_token'], params['app_id'], params['username'], params['password'])
      to_numbers.each {|to| service.send_sms from: from, to: to, msg: msg }
    end
  end
end