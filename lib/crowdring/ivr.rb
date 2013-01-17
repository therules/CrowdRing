module Crowdring
  class KeyOption
    include DataMapper::Resource

    property :id, Serial
    property :press, String, required: true
    property :for, String, required: true
    property :ringer_count, Integer, required: false, default: 0

    validates_with_method :press, :valid_keys?

    def increment
      update! ringer_count: ringer_count + 1
    end

    def to_s
      "Press #{press} for #{self.for} has #{ringer_count}"
    end

    private

    def valid_keys?
      key_pool.include?(press) ? true : [false, "Invalid press key"]
    end

    def key_pool
      (0..9).to_a.map{|a| a.to_s} << "*" << "#" << "+"
    end
  end

  class Ivr
    include DataMapper::Resource

    property :id, Serial
    property :activated, Boolean, default: true
    property :read_text, Text, lazy: false
    property :question, Text, lazy: false

    has n,  :key_options, "KeyOption", through: Resource, constraint: :destroy

    validates_presence_of :key_options

    before :create do 
      set_read_text
    end

    def deactivate
      update(activated: false)
    end

    def key_options=(keyoption)
      return super key_options unless keyoption.is_a? Hash
      keyoption = keyoption.values
      keyoption.each do |ko|
        new_ivr =  KeyOption.create(press: ko["press"], for: ko["for"])
        key_options << new_ivr if new_ivr.save
      end
    end

    def valid_keys
      key_options.each {|k| k.press.to_i}
    end

    def set_read_text
      text_to_read = key_options.map do |option|
        "press #{option.press} for #{option.for}"
      end.join(' ')
      self.read_text = @question + ' ' + text_to_read
      true
    end
  end
end
