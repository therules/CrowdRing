module Crowdring
  class Supporter
    include DataMapper::Resource
    include PhoneNumberFields

    property :id,           Serial
    property :phone_number, String
    property :created_at,   DateTime

    belongs_to :campaign

    validates_with_method :phone_number, :valid_phone_number?

    after :save do |s|
      data = {  number: s.pretty_phone_number,
                supporter_count: s.campaign.supporters.count,
                new_supporter_count: s.campaign.new_supporters.count }
      begin
        Pusher[s.campaign.phone_number[1..-1]].trigger('new', data) 
      rescue SocketError
        p "SocketError: Failed to send message to Pusher"
      end
    end

    def support_date
      created_at.strftime('%F')
    end

  end
end