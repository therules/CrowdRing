module Crowdring
  module NumberPool
    module_function

    def available_summary(type=:voice)
      NumPool.new.summary(type)
    end

    def find_number(opts, type=:voice)
      NumPool.new.find_number(opts, type)
    end

    def find_numbers(opts, type=:voice)
      NumPool.new.find_numbers(opts, type)
    end


    private

    class NumPool
      attr_accessor :voice_numbers, :sms_numbers

      def initialize
        used_voice_numbers = AssignedVoiceNumber.all.map(&:phone_number)
        avail_voice_numbers = CompositeService.instance.voice_numbers - used_voice_numbers
        @voice_numbers = avail_voice_numbers.map {|n| Phoner::Phone.parse n }
        used_sms_numbers = AssignedSMSNumber.all.map(&:phone_number)
        avail_sms_numbers = CompositeService.instance.sms_numbers - used_sms_numbers
        @sms_numbers = avail_sms_numbers.map{|n| Phoner::Phone.parse n}
      end

      def summary(type)
        summary = summary_with_numbers(type)
        summary.map {|entry| entry.delete(:numbers); entry}
      end


      def summary_with_numbers(type)
        numbers = numbers_of_type(type).compact
        region_summary = numbers.reduce({}) do |summary, number|
          country = number.country.name
          regions = Regions.strs_for(number).join(', ')
          key = country + regions

          unless summary.key?(key)
            summary[key] = {country: country, count: 0}
            summary[key][:region] = regions unless regions.empty?
            summary[key][:numbers] = []
          end
          summary[key][:numbers] << number.to_s
          summary[key][:count] += 1
          summary
        end      

        Hash[region_summary.sort].values
      end

      def find_numbers(opts, type)
        avail_numbers = summary_with_numbers(type)
        found_numbers = []
        opts.each do |opt|
          region = find_matching(opt, avail_numbers)
          found_number = region && region[:numbers].first
          found_numbers << found_number
          region[:numbers].delete(found_number) if region
        end
        found_numbers
      end


      def find_number(opts, type)
        region = find_matching(opts, summary_with_numbers(type))
        region && region[:numbers].first
      end

      private

      def numbers_of_type(type)
        case type
        when :voice
          @voice_numbers
        when :sms
          @sms_numbers
        end
      end

      def find_matching(opts, numbers)
        numbers.find do |summary|
          if opts[:region]
            summary[:country] == opts[:country] && summary[:region] && summary[:region] == opts[:region]
          else
            summary[:country] == opts[:country]
          end
        end
      end
    end
  end
end