module Crowdring
  class Filter
    @@filters = {}
    def self.create(name)
      className, *modifier = name.split(':')
      @@filters[className].new(modifier.join(':'))
    end

    def initialize(*args)
    end

    def self.register name
      @@filters[name] = self
    end
  end

  class AllFilter < Filter
    def filter(input)
      input
    end

    register 'all'
  end

  class AfterFilter < Filter
    def initialize(cutoff)
      @cutoff = DateTime.parse cutoff
    end

    def filter(input)
      input.select {|item| item.created_at > @cutoff }
    end

    register 'after'
  end

  class CountryFilter < Filter
    def initialize(countries)
      @countries = countries.split('|')
    end

    def filter(input)
      input.select {|item| @countries.include? item.country.char_3_code }
    end

    register 'country'
  end
end