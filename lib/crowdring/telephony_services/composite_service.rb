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

    def voice_numbers
      @services.values.select(&:voice?).map(&:numbers).flatten
    end

    def sms_numbers
      @services.values.select(&:sms?).map(&:numbers).flatten
    end

    def send_sms(params)
      service = sms_service_for(params[:from])
      params[:from] = service.numbers.first if service == @default_service
      service.send_sms(params)
    end

    def broadcast(from, msg, to_numbers)
      return if to_numbers.empty?
      
      service = sms_service_for(from)
      from = service.numbers.first if service == @default_service

      to_numbers.each_slice(10) do |numbers|
        service.broadcast(from, msg, numbers)
      end
    end

    private

    def sms_service_for(number)
      service = @services.values.find {|s| supports_number(s, number) && s.sms? } || @default_service
      raise NoServiceError, "No service handler for #{number}" if service.nil?
      service
    end

    def supports_number(service, number)
      service.numbers.include? number
    end
  end
end