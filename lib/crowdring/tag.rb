module Crowdring
  class Tag
    include DataMapper::Resource
    @readable = {}

    property :group, String, key: true
    property :value, String, key: true
    property :hidden, Boolean, default: false

    before :save do |tag|
      tag.group = tag.group.downcase
      tag.value = tag.value.downcase
    end

    # str of format "type:value"
    def self.from_str(str, opts={hidden: false})
      group, value = str.split(':')
      group = (group || '').downcase
      value = (value || '').downcase
      Tag.first(group: group, value: value) || Tag.create(group: group, value: value, hidden: opts[:hidden])
    end

    def self.visible
      all(hidden: false)
    end

    def to_s
      "#{group}:#{value}"
    end

    def readable_group
      Tag.readable_group(self)
    end

    def readable_value
      Tag.readable_value(self)
    end

    def readable_s
      "#{readable_group}:#{readable_value}"
    end

    def self.readable_group(tag)
      @readable[tag.group] ? @readable[tag.group][:group] : tag.group
    end

    def self.readable_value(tag)
      @readable[tag.group] ? @readable[tag.group][:value].(tag.value) : tag.value
    end

    def self.register(group, readable_group, &block)
      @readable[group] = {group: readable_group, value: block}
    end

    register('rang', 'Missed Called') {|value| AssignedVoiceNumber.first(id: value).pretty_phone_number }
    register('campaign', 'Campaign Support') {|value| Campaign.get(value).title }
    register('ask_recipient', 'Received Ask') {|value| Ask.get(value).title }
    register('ask_respondent', 'Responded to Ask') {|value| Ask.get(value).title }
  end

end