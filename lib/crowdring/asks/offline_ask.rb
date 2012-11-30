module Crowdring
  class OfflineAsk < Ask
    def title
      'Offline Ask'
    end

    def handle?(type, ringer)
      type == :voice
    end

    def recipient_tag
      Tag.from_str("ask_recipient:#{id}", hidden: true)
    end

    def respondent_tag
      Tag.from_str("ask_respondent:#{id}", hidden: true)
    end

    def self.typesym
      :offline_ask
    end
  end
end