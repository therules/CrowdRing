module Crowdring
  class FilteredMessage
    include DataMapper::Resource

    property :id,       Serial
    property :message,  String, required: true
    property :priority, Integer

    has 1, :tag_filter, constraint: :destroy

    def send_message(params)
      if tag_filter.accept?(params[:to])
        CompositeService.instance.send_sms(
          from: params[:from], to: params[:to].phone_number, 
          msg: message)
        nil
      else
        params[:to]
      end
    end

  end
end