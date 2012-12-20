module Crowdring
  class CsvField
    @fields = []
    @default_fields = []

    attr_reader :id, :display_name

    def initialize(id, display_name)
      @id = id
      @display_name = display_name
    end

    def default?
      CsvField.default? self.id
    end

    class << self
      def add_field(id, display_name, opts={})
        field = CsvField.new(id, display_name)
        @fields << field
        @default_fields << field if opts[:default]
      end

      def all_fields
        @fields
      end

      def default_fields
        @default_fields
      end

      def default?(id)
        @default_fields.map(&:id).include?(id)
      end

      def from_id(id)
        @fields.find {|f| f.id == id.to_s }
      end
    end

    add_field 'phone_number', 'Phone Number', default: true
    add_field 'created_at', 'Support Date', default: true
    add_field 'country_code', 'Country Code'
    add_field 'area_code', 'Area Code'
    add_field 'country_abbreviation', 'Country Abbreviation'
    add_field 'country_name', 'Country'
    add_field 'campaign_support', 'Joined Campaign'
  end
end
