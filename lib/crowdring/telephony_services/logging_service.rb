module Crowdring
  class LoggingRequest
    attr_reader :from, :to, :message

    def initialize(request)
      @to = request.GET['to']
      @from = request.GET['from']
      @message = request.GET['msg'] if request.GET['msg']
    end

    def callback?
      false
    end
  end

  class LoggingService < TelephonyService
    supports :voice, :sms
    request_handler LoggingRequest

    attr_reader :last_sms, :last_broadcast

    def initialize(numbers, opts={})
      @numbers = numbers
      @do_output = opts[:output]
    end

    def build_response(from, commands)
      @last_response = "Reponse: From: #{from}, Commands: #{commands}"
      p @last_response if @do_output
      @last_response
    end

    def numbers
      @numbers
    end

    def send_sms(params)
      @last_sms = params
      p "Send SMS: #{params}" if @do_output
    end

    def broadcast(from, msg, to_numbers)
      @last_broadcast = {from: from, msg: msg, to_numbers: to_numbers }
      p "Broadcast: from: #{from}, msg: '#{msg}', to: #{to_numbers}" if @do_output
    end
  end

  class VoiceLoggingService < TelephonyService
    supports :voice
    request_handler LoggingRequest

    def initialize(numbers, opts={})
      @numbers = numbers
      @do_output = opts[:output]
    end

    def build_response(from, commands)
      response = ""
      builder = Builder::XmlMarkup.new(indent: 2, target: response)
      builder.instruct! :xml
      builder.response do |r|
        commands.each do |c|
          case c[:cmd]
          when :sendsms
            r.sendsms c[:msg], to: c[:to]
          when :reject
            r.hangup
          end
        end
      end
      p response if @do_output
    end

    def numbers
      @numbers
    end

    
  end

  class SMSLoggingService < TelephonyService
    supports :sms

    def initialize(numbers, opts={})
      @numbers = numbers
      @do_output = opts[:output]
    end

    def build_response(from, commands)
      @last_response = "Response: From: #{from}, Commands: #{commands}"
      p @last_response if @do_output
      @last_response
    end

    def numbers
      @numbers
    end

    def send_sms(params)
      @last_sms = params
      p "Send SMS: #{params}" if @do_output
    end

    def broadcast(from, msg, to_numbers)
      @last_broadcast = {from: from, msg: msg, to_numbers: to_numbers }
      p "Broadcast: from: #{from}, msg: '#{msg}', to: #{to_numbers}" if @do_output
    end
  end
end