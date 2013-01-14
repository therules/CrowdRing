module Crowdring
  module NumberPool
    module_function

    def available_summary(type=:voice)
      NumPool.new.summary(type)
    end

    def find_single_number(opts, type=:voice)
      NumPool.new.find_number(opts, type)
    end

    def find_numbers(opts, type=:voice)
      NumPool.new.find_numbers(opts, type)
    end

    def available_voice_with_sms
      available_summary(:voice).reject {|n| find_single_number({country: n[:country]}, :sms).nil? }
    end

    private

    class NumPool
      attr_accessor :voice_numbers, :sms_numbers

      def initialize
        used_voice_numbers = AssignedVoiceNumber.all.map(&:raw_number)
        
        avail_voice_numbers = CompositeService.instance.voice_numbers - used_voice_numbers
        @voice_numbers = avail_voice_numbers

        used_sms_numbers = AssignedSMSNumber.all.map(&:raw_number)
        avail_sms_numbers = CompositeService.instance.sms_numbers - used_sms_numbers
        @sms_numbers = avail_sms_numbers
      end

      def summary(type)
        summary = summary_with_numbers(type)
        summary.map {|entry| entry.delete(:numbers); entry}
      end


      def summary_with_numbers(type)
        numbers = numbers_of_type(type)
        region_summary = numbers.reduce({}) do |summary, raw_number|
          number = Phonie::Phone.parse(raw_number) || ShortCode.parse(raw_number)

          country = number.country.name
          regions = Regions.strs_for(number).join(', ')
          key = country + regions

          unless summary.key?(key)
            summary[key] = {country: country, count: 0}
            summary[key][:region] = regions unless regions.empty?
            summary[key][:numbers] = []
          end
          summary[key][:numbers] << raw_number
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