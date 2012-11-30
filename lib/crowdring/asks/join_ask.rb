module Crowdring
  class JoinAsk < Ask
    def handle?(type, ringer)
      type == :voice && super(type, ringer)
    end

    def self.typesym
      :join_ask
    end
  end
end