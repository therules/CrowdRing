module Crowdring
  class Tag
    include DataMapper::Resource

    property :type, String, key: true
    property :value, String, key: true

    before :save do |tag|
      tag.type = tag.type.downcase
      tag.value = tag.value.downcase
    end

    # str of format "type:value"
    def self.from_str(str)
      type, value = str.split(':')
      Tag.first_or_create(type: type.downcase, value: value.downcase)
    end
  end
end