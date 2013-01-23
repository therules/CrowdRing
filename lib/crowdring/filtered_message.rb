module Crowdring
  class FilteredMessage
    include DataMapper::Resource

    property :id,       Serial
    property :message_text,  Text, lazy: false, required: true
    property :priority, Integer

    has 1, :tag_filter, through: Resource, constraint: :destroy

    def constraints=(constraints)
      self.tag_filter = TagFilter.create(constraints: constraints)
    end

    def accept?(ringer, sms_number)
      tag_filter.accept?(ringer) && ringer.subscribed? && local?(ringer.phone_number, sms_number)
    end

    def send_message(params)
      if accept?(params[:to], params[:from])
        CompositeService.instance.send_sms(
          from: params[:from], to: params[:to].phone_number, 
          msg: message_text)
        true
      else
        false
      end
    end

    def local?(phone_number, sms_number)
      ringer_number = Phonie::Phone.parse(phone_number)
      sms_number = ShortCode.shortcode?(sms_number) ? ShortCode.new : Phonie::Phone.parse(sms_number)
      ringer_number.country == sms_number.country
    end
  end
end