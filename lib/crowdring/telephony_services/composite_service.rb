require 'singleton'

module Crowdring

  class NoServiceError < StandardError; end

  class CompositeService 
    include Singleton

    def initialize
      @default_service_name = nil
      @services = {}
    end

    def add(name, service, opts={})
      @default_service_name = name if opts[:default]
      @services[name] = service
    end

    def get(name)
      @services[name]
    end

    def reset
      @services = {}
      @default_service_name = nil
    end

    def voice_numbers
      @services.values.select(&:voice?).map(&:numbers).flatten
    end

    def sms_numbers
      @services.values.select(&:sms?).map(&:numbers).flatten
    end

    def send_sms(params)
      service_name = service_for(:sms, params[:from])
      service = @services[service_name]
      params[:from] = service.numbers.first if service_name == @default_service_name
      service.send_sms(params)
    end

    def broadcast(from, msg, to_numbers)
      return if to_numbers.empty?
      
      service_name = service_for(:sms, from)
      service = @services[service_name]
      from = service.numbers.first if service_name == @default_service_name

      to_numbers.each_slice(10) do |numbers|
        service.broadcast(from, msg, numbers)
      end
    end

    def service_for(type, number)
      @services.each {|name, service| return name if supports_number(service, number) && service.send("#{type}?") }
      return @default_service_name if @default_service_name

      raise NoServiceError, "No service handler for #{number}"
    end

    private

    def supports_number(service, number)
      service.numbers.include? number
    end
  end
end