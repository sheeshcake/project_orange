extends Node

var server_info = {
	name = "Server",    # Holds the name of the server
	max_players = 0,    # Maximum allowed connections
	used_port = 32788,      # Listening port
	ip_addr = '',		# IP address of the host
}

# Stores my player's info for the game
var my_info = {
	name = "Player",                   # How this player will be shown within the GUI
	net_id = 1,                        # By default everyone receives "server ID"
	actor_path = "res://Player/Player.tscn",  # The class used to represent the player in the game world
	actor_name = "Adventurer",
	spawnpoint = 0
}

var chosen_map : String = "Test_Map"

# Stores ALL players' info, including self. Looks like:
var players_info = {
#	1 = {
#		name = "Player",
#		net_id = 1,
#		actor_path = "res://Characters/Adventurer/Adventurer.tscn",
#		...
#	}
#   823475982372 = {
#		name = "Player",
#		net_id = 823475982372,
#		actor_path = "res://Characters/Adventurer/Adventurer.tscn",
#	 	...
#	}
}

var score_board = {
#	1 = {
#		name = "some player",
#		kills = 2,
#		killed_by = "another player"
#	}
}

var remaining_players : Array
var is_game_ongoing : bool = false # Only for server, will be false all the time for clients

signal server_created	  		# when current machine successfuly creates server
signal host_fail				# When current machine is unable to host
signal join_success	    		# When current machine successfully joins a server
signal join_fail   				# When current machine is unable to join a server
signal player_list_changed		# Player list has been changed
signal player_removed(id)		# A peer has been removed from the player list
signal disconnected				# When current machine disconnects from server
signal player_joined(id)		# A new peer has joined
signal on_exit_button_pressed	# When current machine presses exit
signal game_already_started		# When current machine tries to join a game that has started

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")

func create_server():
	# Initialize the networking system
	var net = NetworkedMultiplayerENet.new()
	
	# Try to create the server
	if (net.create_server(server_info.used_port, server_info.max_players) == OK):
		# Assign it into the tree
		get_tree().set_network_peer(net)
		# Tell the server has been created successfully
		emit_signal("server_created")
		# Register the server's player in the local player list
		register_player(my_info)
	else:
		emit_signal("host_fail")
		

func join_server(ip, port):
	var net = NetworkedMultiplayerENet.new()
	if (net.create_client(ip, port) == OK):
		get_tree().set_network_peer(net)
	else:
		print("Failed to create client")
		emit_signal("join_fail")

# When current machine successfully connects to server
func _on_connected_to_server():
	emit_signal("join_success")
	# Update the local player_info dictionary
	my_info.net_id = get_tree().get_network_unique_id()
	# Call all peers to register my player
	rpc("register_player", my_info)

remotesync func register_player(pinfo):
	if !is_game_ongoing:
		if get_tree().is_network_server():
			# Distribute the player list information throughout the connected players
			for id in players_info:
				# Send currently iterated player info to the new player
				rpc_id(pinfo.net_id, "register_player", players_info[id])
				if id != 1:
					# Send new player info to currently iterated player
					rpc_id(id, "register_player", pinfo)
		
		players_info[pinfo.net_id] = pinfo	# Actually create the player entry in the dictionary
		emit_signal("player_list_changed") 	# Tell Lobby that player list is updated