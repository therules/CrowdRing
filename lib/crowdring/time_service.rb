require 'logger'
module Crowdring
  class TimeService
    $LOG = Logger.new('log_file.log')

    def initialize(name, service)
      @name = name
      @service = service 
    end

    def method_missing(method, *args, &block)
      start_time = Time.now
      result = @service.send(method, *args, &block)
      end_time = Time.now
      $LOG.debug("#{@name}: #{method}, #{end_time - start_time}s")
      result
    end
  end
end