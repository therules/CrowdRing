module Crowdring
  class ResponseNumbers  < Struct.new(:voice_number, :sms_number)
    def initialize(params)
      self.voice_number = params[:voice_number]
      self.sms_number = params[:sms_number]
    end
  end
end

