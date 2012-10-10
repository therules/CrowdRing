module Crowdring
  class IntroductoryResponse
    include DataMapper::Resource

    property :id, Serial

    has n, :filtered_messages, constraint: :destroy
    
    belongs_to :campaign, required: false

    def filtered_messages=(messages)
      messages = messages.values if messages.is_a? Hash
      messages.each_with_index.each {|m, i| filtered_messages.new(m.merge({priority: i})) }
    end

    def default_message=(message)
      default_filtered_message.destroy if default_filtered_message
      filtered_messages.new(tag_filter: TagFilter.create, message: message, priority: 100)
    end

    def add_message(filter, message)
      filtered_messages.create(tag_filter: filter, message: message, priority: filtered_messages.count)
    end

    def send_message(params)
      prioritized_messages.find {|fm| fm.send_message(params) }
    end

    def default_message
      default_filtered_message.message
    end

    def nondefault_messages
      Enumerator.new do |y|
        prioritized_messages.each do |m|
          y << m unless m.priority == 100
        end
      end
    end    

    private

    def default_filtered_message
      filtered_messages.first(priority: 100)
    end

    def prioritized_messages
      filtered_messages.all(order: [:priority.asc])
    end
  end
end