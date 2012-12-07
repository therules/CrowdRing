module Crowdring
  class JoinAsk < Ask
    validates_presence_of :message
    def handle?(type, ringer)
      type == :voice && super(type, ringer)
    end

    def self.typesym
      :join_ask
    end
  end
end