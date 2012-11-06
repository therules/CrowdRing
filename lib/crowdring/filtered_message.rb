module Crowdring
  class FilteredMessage
    include DataMapper::Resource

    property :id,       Serial
    property :message_text,  String, required: true, length: 255
    property :priority, Integer

    has 1, :tag_filter, through: Resource, constraint: :destroy

    def tags=(tags)
      self.tag_filter = TagFilter.create(tags: tags)
    end

    def accept?(ringer)
      tag_filter.accept?(ringer)
    end

    def send_message(params)
      if tag_filter.accept?(params[:to])
        CompositeService.instance.send_sms(
          from: params[:from], to: params[:to].phone_number, 
          msg: message_text)
        true
      else
        false
      end
    end

  end
end