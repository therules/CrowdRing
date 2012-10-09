module Crowdring
  module RegionTags
    @@region_hash = nil
    module_function

    def region_hash
      return @@region_hash unless @@region_hash.nil?

      data_file = File.join(File.dirname(__FILE__), '../..', 'data', 'regions.yml')
      @@region_hash = YAML.load(File.read(data_file))
      @@region_hash
    end

    def tags_for(number)
      return [] if (regions = region_hash[number.country.name.downcase]).nil?
      regions[number.area_code.to_i].map { |region| Tag.from_str('region:' + region)}
    end
  end
end