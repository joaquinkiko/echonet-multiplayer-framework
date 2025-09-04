## Optional global class for monitoring and debugging Echonet Multiplayer
extends Node

const SHOULD_TILE_IN_EDITOR := true

@onready var statistics_control: Control = $Statistics
@onready var label_status: Label = $Statistics/Status
@onready var label_address: Label = $Statistics/Address
@onready var label_data_in: Label = $Statistics/Data/In
@onready var label_data_out: Label = $Statistics/Data/Out
@onready var label_packets_in: Label = $Statistics/Packets/In
@onready var label_packets_out: Label = $Statistics/Packets/Out
@onready var label_rtt: Label = $Statistics/RTT/Msec
@onready var label_throttle: Label = $Statistics/Throttle/Value
@onready var label_loss: Label = $Statistics/Loss/Value
@onready var label_clients: Label = $Statistics/Clients
@onready var label_time: Label = $Statistics/Time/Time
@onready var label_tick: Label = $Statistics/Time/Tick
@onready var avg_packet_in: Label = $Statistics/PacketData/In
@onready var avg_packet_out: Label = $Statistics/PacketData/Out

## Array of seven server statistics sorted as
## 0:data in	1:data out	2:packets in	3:packets out	4:rtt	5:throttle	6:packet loss
var statistics := PackedInt64Array([0,0,0,0,0,0,0])

var _next_monitor_update_msec := 0
var _instance_num := -1
var _instance_socket: TCPServer 

func _init() -> void:
	if !OS.is_debug_build():
		queue_free()
		return
	_instance_socket = TCPServer.new()
	for n in range(0,4):
		if _instance_socket.listen(5000 + n) == OK:
			_instance_num = n
			break

func _ready() -> void:
	# Tile windows in editor
	if SHOULD_TILE_IN_EDITOR && OS.has_feature("editor"):
		var window := get_window()
		var screen_i := DisplayServer.window_get_current_screen()
		var screen := DisplayServer.screen_get_usable_rect(screen_i)
		var y_mod := DisplayServer.window_get_size_with_decorations().y - DisplayServer.window_get_size().y - 10
		window.size = DisplayServer.screen_get_usable_rect(screen_i).size / 2
		window.size.y -= y_mod
		match _instance_num:
			0:
				window.position.x = screen.position.x
				window.position.y = screen.position.y + y_mod
			1:
				window.position.x = screen.position.x + window.size.x
				window.position.y = screen.position.y + y_mod
			2:
				window.position.x = screen.position.x
				window.position.y = screen.position.y + y_mod * 2 + window.size.y
			3:
				window.position.x = screen.position.x + window.size.x
				window.position.y = screen.position.y + y_mod * 2 + window.size.y
	# Run launch args
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--transport="):
			match arg.trim_prefix("--transport="):
				"local": Echonet.transport=LocalTransport.new()
				"enet": Echonet.transport=ENetTransport.new()
		if arg.begins_with("--nickname="): 
			Echonet.local_nickname = arg.trim_prefix("--nickname=")
		if arg.begins_with("--servername="): 
			Echonet.transport.server_name = arg.trim_prefix("--servername=")
		if arg.begins_with("--maxpeers="): 
			Echonet.transport.max_peers = int(arg.trim_prefix("--maxpeers="))
		if arg.begins_with("--serverpassword="): 
			Echonet.transport.password = Echonet.transport.hash_password(arg.trim_prefix("--serverpassword="))
		if arg.begins_with("--serverauth="): 
			Echonet.transport.authentication_hash = arg.trim_prefix("--serverauth=").sha1_buffer()
		if arg.begins_with("--clientuid="): 
			Echonet.local_uid = int(arg.trim_prefix("--clientuid="))
		if arg.begins_with("--tickrate="): 
			Echonet.transport.tick_rate = int(arg.trim_prefix("--tickrate="))
	if args.has("--server"):
		if DisplayServer.get_name() == "headless": Echonet.transport.init_headless_server()
		elif args.has("--visual-headless"): Echonet.transport.init_headless_server()
		else: Echonet.transport.init_server()
	elif args.has("--client"): Echonet.transport.init_client()

func _process(delta: float) -> void:
	label_time.text = str(Echonet.transport.server_time)
	label_tick.text = str(Echonet.transport.tick)
	if Time.get_ticks_msec() >= _next_monitor_update_msec:
		var data := Echonet.transport.gather_statistics()
		for n in 7: statistics[n] = data[n]
		label_data_in.text = "%s/s"%String.humanize_size(data[0])
		label_data_out.text = "%s/s"%String.humanize_size(data[1])
		label_packets_in.text = "%s/s"%data[2]
		label_packets_out.text = "%s/s"%data[3]
		label_rtt.text = "%smsec"%data[4]
		label_throttle.text = "%s%%"%data[5]
		label_loss.text = "%s%%"%data[6]
		avg_packet_in.text = "%s"%String.humanize_size(data[0] / max(1, data[2]))
		avg_packet_out.text = "%s"%String.humanize_size(data[1] / max(1, data[3]))
		
		if Echonet.transport.is_connected:
			if Echonet.transport.connection_successful:
				if Echonet.transport.is_server: 
					label_status.text = "Server (%s) (%s/%s)"%[Echonet.transport.server_name,
						Echonet.transport.client_peers.size(),
						Echonet.transport.max_peers]
					if !Echonet.transport.is_joinable: label_status.text += " Private"
				elif Echonet.transport.is_client: 
					label_status.text = "Client (%s) (%s/%s)"%[Echonet.transport.server_name,
						Echonet.transport.client_peers.size(),
						Echonet.transport.max_peers]
					if !Echonet.transport.is_joinable: label_status.text += " Private"
				else: label_status.text = "Non-player Client"
			else: label_status.text = "Connecting..."
		else: label_status.text = "Offline"
		if Echonet.transport is ENetTransport:
			label_address.text = "%s:%s"%[Echonet.transport.ip, Echonet.transport.port]
		else:
			label_address.text = ""
		
		if Echonet.transport.is_connected:
			label_clients.text = ""
			for client in Echonet.transport.client_peers.values():
				if client.is_server: label_clients.text += "(S)"
				elif client.is_admin: label_clients.text += "(A)"
				label_clients.text += "%s (%s)"%[client.nickname, client.uid]
				if Echonet.transport.is_server:
					label_clients.text += " rtt: %sms\n"%client.rtt
				else: label_clients.text += "\n"
		else: label_clients.text = ""
		
		_next_monitor_update_msec = Time.get_ticks_msec() + 1000
