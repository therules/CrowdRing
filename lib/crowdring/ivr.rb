module Crowdring
  class KeyOption
    include DataMapper::Resource

    property :id, Serial
    property :press, String, required: true
    property :for, String, required: true
    property :ringer_cound, Integer, required: false, default: 0

    belongs_to :ivr, required: true
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

    def set_read_text
      text_to_read = @keyoption.map do |option_hash|
        k, v = option_hash.keys.first, option_hash.values.first
          k.to_s + ' ' + v.to_s
      end.join(' ')
      self.read_text = @auto_text + ' ' + text_to_read
    end
  end
end
