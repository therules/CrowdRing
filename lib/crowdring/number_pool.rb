module Crowdring
  module NumberPool
    module_function

    def available_summary
      NumPool.new.available_summary
    end

    def assign_voice(opts)
      NumPool.new.assign_voice(opts)
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
        region_summary = available_numbers.reduce({}) do |summary, number|
          country = number.country.name
          regions = Regions.strs_for(number).join(', ')
          key = country + regions

          unless summary.key?(key)
            summary[key] = {country: country, count: 0}
            summary[key][:region] = regions unless regions.empty?
          end
          summary[key][:count] += 1
          summary
        end      

        region_summary.values
      end
    end
  end
end