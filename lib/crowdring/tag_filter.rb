module Crowdring
  class TagFilter
    include DataMapper::Resource

    property :id, Serial

    has n, :constraints, constraint: :destroy

    def filter(items)
      items.select do |item|
        accept? item
      end
    end

    def constraints=(constraints)
      return if constraints.nil?

      constraints = constraints.map {|str| Constraint.from_str(str) } if constraints.first.is_a?(String)
      super constraints
    end

    def accept?(item)
      constraints.reduce(true) {|acc, con| acc and con.satisfied_by? item }
    end
  end
end

