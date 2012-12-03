module Crowdring
  class TagFilter
    include DataMapper::Resource

    property :id, Serial

    has n, :tags, through: Resource, constraint: :skip

    def filter(items)
      items.select do |item|
        accept? item
      end
    end

    def tags=(tags)
      return if tags.nil?
      tags = tags.map {|str| Tag.from_str(str)} if !tags.empty? && tags.first.is_a?(String)
      super tags
    end

    def accept?(item)
      tags.reduce(true) {|acc, tag| acc and item.tags.include? tag }
    end
  end
end