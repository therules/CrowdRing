module Crowdring
  module NumberPool
    module_function

    def available_summary
      NumPool.new.available_summary
    end

    def find_numbers(opts)
      NumPool.new.find_numbers(opts)
    end


    private

    class NumPool
      attr_accessor :available_numbers

      def initialize
        used_voice_numbers = AssignedVoiceNumber.all.map(&:phone_number)
        avail_numbers = CompositeService.instance.voice_numbers - used_voice_numbers
        @available_numbers = avail_numbers.map {|n| Phoner::Phone.parse n }
      end

      def available_summary
        available_summary = available_whole_summary
        available_summary.map{|summary| summary.delete(:number)}
        available_summary
      end

      def available_whole_summary 
        region_summary = available_numbers.reduce({}) do |summary, number|
          country = number.country.name
          regions = Regions.strs_for(number).join(', ')
          key = country + regions

          unless summary.key?(key)
            summary[key] = {country: country, count: 0}
            summary[key][:region] = regions unless regions.empty?
            summary[key][:number] = number.to_s
          end
          summary[key][:count] += 1
          summary
        end      

        region_summary.values
      end

      def find_numbers(opts)
        opts.map{|opt| find_number(opt)}
      end

      def find_number(opts)
        number = available_whole_summary.find do |summary|
          if opts[:region]
            summary[:country] == opts[:country] && summary[:region] && opts[:region]
          else
            summary[:country] == opts[:country]
          end
        end
        number[:number]
      end

    end
  end
end