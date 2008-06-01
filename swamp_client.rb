# Client for Swamp-BCM
require 'drb'

DRb.start_service

class ::State
	include DRbUndumped
	attr_accessor :nick
	attr_accessor :writer_proc
	def initialize
		@nick = ""
		@writer_proc = proc{|nick,msg|}
	end
	def recv(nick, msg)
		@writer_proc.call nick, msg
	end
end

class Swamp < Shoes
	url '/', :connect
	url '/goto', :goto
	url '/chat', :chat
	def layout
		background "#00A".."#09A"
	end
	def connect
		layout
		stack do
			title "Swamp: Connect to Server", :stroke => white
			flow { para "Server: ", :stroke => yellow; @server_line = edit_line :width => 300 }
			flow { para "Nickname: ", :stroke => yellow; @nick_line = edit_line :width => 300 }
			button("Connect") do
				$server = DRbObject.new(nil, "druby://#{@server_line.text}:17765")
				$state = ::State.new
				$state.nick = @nick_line.text
				if ($server.is_swamp_server? rescue nil)
					visit "/goto"
				else
					alert "Can not connect to server."
				end
			end
		end
	end
	def goto
		layout
		stack do
			title "Swamp: Go to Room", :stroke => white
			caption "Logged in as #{$state.nick}. Lag time: #{$server.test_lag_time(Time.now)} seconds.", :stroke => white
			flow { para "Room Name: ", :stroke => yellow; @goto_line = edit_line :width => 300 }
			flow { button("Open") do
				$room, $token = $server.join_room($state, @goto_line.text)
				visit "/chat"
			end; button("Disconnect") do
				visit "/"
			end }
			caption "#{$server.online_count} users online.", :stroke => "#CCC"
		end
	end
	def chat
		layout
		stack do
			title "Swamp: #{$room.name}", :stroke => white
			@cap = flow {s = $room.occupants.size; caption "#{s} #{(s == 1) ? "person" : "people"} in room.", :stroke => white}
			button "Leave Room" do
				$room.leave $token
				visit "/goto"
			end
			flow { para "Message: ", :stroke => yellow; @message_line = edit_line :width => 480; button "Send" do
				$room.message $token, @message_line.text
				@message_line.text = ""
				@cap.clear {s = $room.occupants.size; caption "#{s} #{(s.size == 1) ? "person" : "people"} in room."}
			end }
			stack(:width => "100%") { background "#FFF".."#CCC"; border yellow; @chatbox = flow {} }
			$state.writer_proc = proc do |nick, msg|
				@chatbox.prepend { para(strong(nick), " ", msg, "\n", :stroke => black) }
				@cap.clear {s = $room.occupants.size; caption "#{s} #{(s.size == 1) ? "person" : "people"} in room.", :stroke => white}
			end
		end
	end
end

Shoes.app :width => 640, :height => 480, :title => "Swamp Messenger"

