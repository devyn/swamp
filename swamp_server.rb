# Bouncer/Server for Swamp-BCM

require 'drb'

class Room
	include DRbUndumped
	attr_reader :name
	def initialize(name)
		@name = name
		@occupants = {}
	end
	def occupants
		@occupants.values.collect{|o|o.nick}
	end
	def enter(state)
		puts "#{state.nick} is entering #{@name}..." if $DEBUG
		token = rand(0xFFFFFFFF).to_s 16
		@occupants[token] = state
		return [self, token]
	end
	def leave(token)
		puts "#{@occupants[token].nick} is leaving #{@name}..." if $DEBUG
		@occupants.delete token
		$bouncer.instance_variable_get("@rooms").delete self if @occupants.empty?
		true
	end
	def message(token, msg)
		puts "Message sent by #{@occupants[token].nick}." if $DEBUG
		if state = @occupants[token]
			@occupants.values.each do |o|
				o.recv state.nick, msg
				puts "Relayed to #{o.nick}." if $DEBUG
			end
			true
		else
			false
		end
	end
end
class Bouncer
	def initialize
		@rooms = []
	end
	def join_room(state, name)
		if room = @rooms.select{|r| r.name == name}.first
			return room.enter(state)
		else
			room = Room.new name
			@rooms << room
			return room.enter(state)
		end
	end
	def is_swamp_server?
		puts "Initial ping from client..." if $DEBUG
		true
	end
	def online_count
		eval(@rooms.collect{|r|r.instance_variable_get("@occupants").size}.join("+")).to_i
	end
	def test_lag_time(_then)
		_now = Time.now
		puts "Client is testing lag time. (#{_now - _then}s)" if $DEBUG
		_now - _then
	end
end

if __FILE__ == $0
	$bouncer = Bouncer.new
	DRb.start_service "druby://:17765", $bouncer
	trap("INT") {puts "Server Stopping..." if $DEBUG; DRb.stop_service; exit}
	puts "Server Loaded." if $DEBUG
	DRb.thread.join
end
