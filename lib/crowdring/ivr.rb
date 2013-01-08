module Crowdring
  class IVR
    include DataMapper::Resource

    property :id, Serial
    property :title, String, length: 64
    property :activated, Boolean, default: false
    property :read_text, String, required: true
    

    def activate
      update(activated: true)
    end

    def deactivate
      update(activated: false)
    end

    def read_text(auto_text, keyoption)
      read_text = read_text 
                + keyoption.inject(""){|res, ele| res += ele.map{|k,v| ' ' + v.to_s}.join(' ');res}
                + auto_text
    end
  end
end








