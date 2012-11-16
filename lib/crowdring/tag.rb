module Crowdring
  class Tag
    include DataMapper::Resource

    property :group, String, key: true
    property :value, String, key: true
    property :type, Discriminator

    before :save do |tag|
      tag.group = tag.group.downcase
      tag.value = tag.value.downcase
    end

    # str of format "type:value"
    def self.from_str(str)
      group, value = str.split(':')
      Tag.first_or_create(group: (group || '').downcase, value: (value || '').downcase)
    end

    def to_s
      "#{group}:#{value}"
    end
  end

  class RingTag < Tag
    def self.from_str(id)
      RingTag.first_or_create(group: 'rang', value: id)
    end

    def to_s
      number = AssignedVoiceNumber.first(id: value)
      if number
        "Rang #{AssignedVoiceNumber.first(id: value).pretty_phone_number}"
      else
        nil
      end
    end
  end

end