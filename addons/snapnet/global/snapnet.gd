## Global Snapnet multiplayer manager
extends Node

## Maximum characters for user nickname
const MAX_NICKNAME_SIZE := 32

## Local user's nickname to share when playing over the network
var local_nickname: String = ""

## Local user's UID to share over network (could be SteamID or custom login uid)
var local_uid: int = 0

## [SnapnetTransport] currently in use-- defaults to [LocalTransport]
var transport: SnapnetTransport:
	get: return _transport
	set(value): 
		if value == null: _transport = LocalTransport.new()
		else: _transport = value
var _transport: SnapnetTransport = LocalTransport.new()

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Default to randomized player nickname on launch
	local_nickname = "Player" + str(randi_range(1000,9999))

func _ready() -> void:
	# Process launch arguments
	var args := OS.get_cmdline_args()
	# Settings arguments
	for arg in args:
		if arg.begins_with("--nickname="): local_nickname = arg.trim_prefix("--nickname=")
		if arg.begins_with("--servername="): transport.server_name = arg.trim_prefix("--servername=")
		if arg.begins_with("--maxpeers="): transport.max_peers = int(arg.trim_prefix("--maxpeers="))
		if arg.begins_with("--serverpassword="): 
			transport.password = arg.trim_prefix("--serverpassword=").sha1_buffer()
		# Debug only settings
		if OS.has_feature("debug"):
			if arg.begins_with("--transport="):
				match arg.trim_prefix("--transport="):
					"local": transport=LocalTransport.new()
					"enet": transport=ENetTransport.new()
			if arg.begins_with("--serverauth="): 
				transport.authentication_hash = arg.trim_prefix("--serverauth=").sha1_buffer()
			if arg.begins_with("--clientuid="): 
				local_uid = int(arg.trim_prefix("--clientuid="))
		if OS.has_feature("editor"):
			if arg.begins_with("--tile="):
				var pos := int(arg.trim_prefix("--tile="))
				var window := get_window()
				window.size = DisplayServer.screen_get_size() / 2
				window.size.y -= 30
				match pos:
					0:
						window.position.x = 0
						window.position.y = 30
					1:
						window.position.x = 0
						window.position.y = 30 + DisplayServer.screen_get_size().y / 2
					2:
						window.position.x = DisplayServer.screen_get_size().x / 2
						window.position.y = 30
					3:
						window.position.x = DisplayServer.screen_get_size().x / 2
						window.position.y = 30 + DisplayServer.screen_get_size().y / 2
	# Headless Server Check
	if OS.has_feature("Server"):
		transport.init_headless_server()
		return
	# Quick Launch Arguments
	if args.has("--server"):
		if args.has("--headless"): transport.init_headless_server()
		else: transport.init_server()
	elif args.has("--client"): transport.init_client()

func _process(_delta: float) -> void:
	transport.handle_events()
