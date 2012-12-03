module Crowdring
  class Constraint
    include DataMapper::Resource

    property :id, Serial 
    property :type, Discriminator

    belongs_to :tag

      def self.from_str(str)
        if str[0] == '!'
          HasNotConstraint.new(tag:Tag.from_str(str[1..-1]))
        else
          HasConstraint.new(tag:Tag.from_str(str))
        end
      end
  end

  class HasConstraint < Constraint
    def satisfied_by?(item)
      item.tags.include? tag
    end

    def to_s
      "has #{tag.readable_s}"
    end
  end

  class HasNotConstraint < Constraint
    def satisfied_by?(item)
      not item.tags.include? tag
    end

    def to_s
      "has not #{tag.readable_s}"
    end
  end
end