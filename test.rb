require 'em-websocket'
require 'redis'

def subscribe(subscribers, channel)
	Thread.new do
		redis = Redis.new(:timeout => 0)
		redis.subscribe(channel) do |on|
			on.message do |chan, msg|
				subscribers.each { |s| s.send msg }
			end
		end
	end
end

subscribers = {}
sockets = {}
EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|

  ws.onopen do
  	puts 'WebSocket opened'
  end

  ws.onmessage do |msg|
  	sockets[ws] = msg
  	unless subscribers.has_key? msg
  		subscribers[msg] = []
  		subscribe(subscribers[msg], msg)
  	end

  	subscribers[msg] << ws
  end

  ws.onclose do
  	puts 'WebSocket closed'
  	subscribers[sockets[ws]].delete(ws)
  	sockets.delete(ws)
  	#sockets[registrations[ws]].delete ws
  end
end

