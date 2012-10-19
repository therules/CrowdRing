module Crowdring
  class TelephonyService
    def sms?
      false
    end

    def voice?
      false
    end

    def self.supports(*types)
      types.each {|type| define_method("#{type}?") { true }}
    end

    def self.request_handler(klass)
      define_method(:transform_request) {|request| klass.new(request) }
    end
  end
end