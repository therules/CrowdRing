module Crowdring
  class FilterTagging
    include DataMapper::Resource

    belongs_to :tag, key: true
    belongs_to :tag_filter, key: true
  end
end