module Crowdring
  class Message
    include DataMapper::Resource

    property :id, Serial

    has n, :filtered_messages, through: Resource, constraint: :destroy

    validates_presence_of :filtered_messages
    

    def filtered_messages=(messages)
     return super messages unless messages.is_a? Hash
      messages = messages.values 
      messages.each_with_index.each {|m, i| filtered_messages.new(m.merge({priority: i})) }
    end

    def default_message=(message)
      return if message.empty?
      default_filtered_message.destroy if default_filtered_message
      filtered_messages.new(tag_filter: TagFilter.create, message_text: message, priority: 100)
    end

    def add_message(filter, message)
      filtered_messages.create(tag_filter: filter, message_text: message, priority: filtered_messages.count)
    end

    def send_message(params)
      prioritized_messages.find {|fm| fm.send_message(params) }
    end

    def for(ringer)
      prioritized_messages.find {|fm| fm.accept?(ringer) }
    end

    def default_message
      if default_filtered_message.nil?
        nil
      else
        default_filtered_message.message_text
      end
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