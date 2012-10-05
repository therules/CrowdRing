module Crowdring
  class IntroductoryResponse
    include DataMapper::Resource

    property :id, Serial

    has n, :filtered_messages, constraint: :destroy
    
    belongs_to :campaign, required: false

    def self.create_with_default(message)
      intro_response = create
      filter = TagFilter.create
      intro_response.filtered_messages.create(tag_filter: filter, message: message, priority: 100)
      intro_response
    end

    def add_message(filter, message)
      filtered_messages.create(tag_filter: filter, message: message, priority: filtered_messages.count)
    end

    def send_message(params)
      prioritized_messages.find {|fm| fm.send_message(params) }
    end

    private

    def prioritized_messages
      filtered_messages.all(order: [:priority.asc])
    end
  end
end