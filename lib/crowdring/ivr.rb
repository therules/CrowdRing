module Crowdring
  class KeyOption
    include DataMapper::Resource

    property :id, Serial
    property :press, String, required: true
    property :for, String, required: true
    property :ringer_count, Integer, required: false, default: 0

    belongs_to :ivr, required: true

    def increment
      update! ringer_count: ringer_count + 1
    end
    
  end

  class Ivr
    include DataMapper::Resource

    property :id, Serial
    property :activated, Boolean, default: true
    property :read_text, Text, lazy: false

    has n,  :key_options, "KeyOption", through: Resource, constraint: :destroy
    
    before :create do 
      set_read_text
    end

    after :create do 
      set_key_option
    end

    def deactivate
      update(activated: false)
    end

    def set_key_option
      @keyoption.each do |ko| 
        a = KeyOption.create(press: ko[:press], for: ko[:for], ivr_id: @id)
        self.key_options << a
      end
      save
    end

    def keyoption=(keyoption)
      @keyoption = keyoption.values
    end

    def auto_text=(auto_text)
      @auto_text = auto_text
    end

    def valid_keys
      key_options.map(&:press)
    end

    def set_read_text
      text_to_read = @keyoption.map do |option_hash|
         [option_hash.keys, option_hash.values].transpose
      end.join(' ')
      self.read_text = @auto_text + ' ' + text_to_read
    end
  end
end
