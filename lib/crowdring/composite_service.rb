require 'singleton'

module Crowdring

  class NoServiceError < StandardError; end

  class CompositeService 
    include Singleton

    def initialize
      @default_service = nil
      @services = {}
    end

    def add(name, service, opts={})
      @default_service = service if opts[:default]
      @services[name] = service
    end

    def get(name)
      @services[name]
    end

    def reset
      @services = {}
      @default_service = nil
    end

    def numbers
      @services.values.map(&:numbers).flatten
    end

    def send_sms(params)
      service = supporting_service(params[:from])

      if service.supports_outgoing?
        service.send_sms(params)
      elsif @default_service
        @default_service.send_sms(from: @default_service.numbers.first,
          to: params[:to], msg: params[:msg])
      else
        raise NoServiceError, "No outgoing service handler for #{params[:from]}"
      end
    end

    private

    def supporting_service(number)
      service = @services.values.find {|s| supports_number(s, number)}
      if service.nil?
        raise NoServiceError, "No service handler for #{number}"
      end
      service
    end

    def supports_number(service, number)
      service.numbers.include? number
    end
  end
end