## Generic class for networking transports-- do not use directly
class_name EchonetTransport extends RefCounted

## Max ticks to simulate per frame
const MAX_TICKS_PER_FRAME := 8

## Time in milliseconds in which server must loop time
const MAX_SERVER_TIME := 4294967295 # u32 max value

const MAX_PEERS := 255 # Max u8

const MAX_TIME_DESYNC := 1000

## Channels for sending data
enum ServerChannels {
	MAIN = 0,
	MAIN_RELIABLE = 1,
	BACKEND = 2,
	CHAT = 3,
	SPAWN = 4,
	MAX = 5
}

## Reason for client/server being disconnected
enum DisconnectReason {
	ERROR = -2,
	UNKNOWN = -1,
	LOST_CONNECTION = 0,
	LOCAL_REQUEST = 1,
	TIMEOUT = 2,
	SERVER_CLOSING = 3,
	KICKED = 4,
	SERVER_PRIVATE = 5,
	FAILED_AUTHENTICATION_HASH = 6,
	FAILED_AUTHENTICATION_PASSWORD = 7,
	FAILED_AUTHENTICATION_WHITELIST = 8,
	FAILED_AUTHENTICATION_IDENTIFICATION = 9,
	FAILED_AUTHENTICATION_BLACKLISTED = 10,
	SERVER_FULL = 11,
	INFO_REQUEST_COMPLETED = 12,
	INFO_REQUEST_TIMEOUT = 13,
	FAILED_TO_VERIFY = 14,
}

## Result of authentication attempt
enum AuthenticationResult {
	FAILED_BLACKLISTED = -4,
	FAILED_TO_GIVE_UID = -3,
	FAILED_WHITELIST = -2,
	FAILED_PASSWORD = -1,
	FAILED_HASH = 0,
	SUCCESS = 1
}

## Called whene server is initialized successfully
signal on_server_initialized()
## Called when client connects to server successfully
signal on_connected_to_server()
## Called when disconnected from server
signal on_disconnected(reason: DisconnectReason)

## Called when remote peer connects to server
signal on_peer_connected(peer_id: int)
## Called when remote peer disconnects from server
signal on_peer_disconnecting(peer_id: int)
## Called when a new packet is received
signal on_packet_received(packet: EchonetPacket)

## Called when server info request is received as a non-client
signal on_server_info_request_received(packet: ServerInfoPacket)

## Called when a chat message is received
signal on_chat_received(message: String, sender: EchonetPeer)

## Called every tick with delta machine time since last tick (not delta server time)
signal on_tick(delta: float)
## Called before every tick loop
signal before_tick_loop()
## Called after every tick loop
signal after_tick_loop()

## Called when time is resyncronized-- Provides relative change in server time
signal on_time_resynced(delta_msec: int)

## Called every input tick with delta machine time since last tick (not delta server time)
signal on_input_tick(delta: float)

## List of connected client-peers sorted by id (including self)
var client_peers: Dictionary[int, EchonetPeer]:
	get: return _client_peers
	set(value): push_error("'client_peers' cannot be set directly")
var _client_peers: Dictionary[int, EchonetPeer]
## Server peer
var server_peer: EchonetPeer:
	get: return _server_peer
	set(value): push_error("'server_peer' cannot be set directly")
var _server_peer: EchonetPeer

## Local machine's peer id
var local_id: int = -1

## How long to wait in msec before connection attempt fails
var connection_timeout_msec: int = 5000

## Max peers allowed in room-- cannot be set while [member is_connected] is true
var max_peers: int:
	get: return _max_peers
	set(value):
		if is_connected: push_error("'max_peers' must be set before connecting")
		elif value < 1: push_error("'max_peers' cannot be set to less than 1")
		elif value > 255: push_error("'max_peers' cannot be set to greater than 255")
		else: _max_peers = value
var _max_peers: int = 32

## Set whether server is currently joinable-- will reset to true on server start
var is_joinable: bool:
	get: return _is_joinable
	set(value):
		_is_joinable = value
		if is_server: server_broadcast(_create_server_info_packet(), ServerChannels.BACKEND, true)
var _is_joinable: bool = true

## Server password for connecting to server / compare against clients (empty for no password)
var password := PackedByteArray([])

## Authentication data for connecting to server / compare against clients
var authentication_hash := PackedByteArray([])

## List of UIDs that are whitelisted for server (leave empty for no whitelist)
var uid_whitelist : PackedInt64Array:
	get: return _uid_whitelist
	set(value): 
		if is_connected: push_error("'uid_whitelist' must be set before connecting")
		else: _uid_whitelist = value
var _uid_whitelist := PackedInt64Array([])

## List of UIDs that are blacklisted for server
var uid_blacklist := PackedInt64Array([])

## List of UIDs that are promoted to admin on joining server
var uid_admin_list := PackedInt64Array([])

## While false server will reject clients with no UID
var allow_empty_uid: bool = true

## While true admin promotions/demotions will be automatically recorded to [member uid_admin_list]
var should_save_admin_status_changes: bool = true

## List of UIDs with flags against them
var uid_flags: Dictionary[int, int]

## Number of flags against a UID before they are banned
var flags_to_ban: int = 3

## List of spawn packets organized by their ID for late joining clients
var _late_join_spawn_packets: Dictionary[int, SpawnPacket]

## Name of current server
var server_name: String:
	get: 
		if _server_name.is_empty(): return "%s's Server"%Echonet.local_nickname
		else: return _server_name
	set(value): 
		_server_name = value
		if is_server: server_broadcast(_create_server_info_packet(), ServerChannels.BACKEND, true)
var _server_name: String

## True if active connection of any type, or attempting connection
var is_connected: bool: 
	get: return _is_connected
	set(value): push_error("'is_connected' cannot be set directly")
var _is_connected: bool = false
## True if active connection as server
var is_server: bool: 
	get: return _is_server
	set(value): push_error("'is_server' cannot be set directly")
var _is_server: bool = false
## True if active connection as client
var is_client: bool: 
	get: return _is_client
	set(value): push_error("'is_client' cannot be set directly")
var _is_client: bool = false
## Must be set to true during connection setup to notify successful connection
var connection_successful: bool:
	get: return _connection_successful
	set(value): push_error("'connection_successful' cannot be set directly")
var _connection_successful: bool = false

var _has_server_info: bool = false
var _has_peer_info: bool = false

## Ticks to simulate per second
var tick_rate: int:
	get: return _tick_rate
	set(value): 
		if is_connected: push_error("'tick_rate' must be set before connecting")
		if value < 1: push_error("'tick_rate' must be atleast 1")
		if value > 255: push_error("'tick_rate' cannot be greater than 255")
		else: _tick_rate = value
var _tick_rate := 30

## Current time in msec since server started
var server_time: int:
	get: return _server_time
	set(value): push_error("Cannot set 'server_time' directly")
var _server_time := 0

## Current server tick
var tick: int:
	get: return _tick
	set(value): push_error("Cannot set 'tick' directly")
var _tick := 0

## Server time of next tick
var _next_tick_time: int = 0
## Milliseconds per tick
var msec_per_tick: int:
	get: return int(1.0 / float(tick_rate) * 1000)

## Returns true if time has been syncronized
var has_synced_time: bool

## Last time a tick was processed for calculating delta (not server time)
var _last_tick_time: int

var _peer_id_counter: int = 2

## Input ticks to simulate per second
var input_rate: int:
	get: return _input_rate
	set(value):
		if value < 1: push_error("'input_rate' must be atleast 1")
		if value > 1000: push_error("'input_rate' cannot be greater than 1000")
		else: _tick_rate = value
var _input_rate := 120

## Next Input tick time
var _next_input_tick_time: int = 0
## Milliseconds per input tick
var msec_per_input_tick: int:
	get: return int(1.0 / float(input_rate) * 1000)
## Last time an input tick was processed for calculating delta (not server time)
var _last_input_tick_time: int

## Last recorded snapshot
var last_snapshot: EchoSnapshot
## Stored [EchoSnapshot] of past ticks, sorted by tick
var stored_snapshots: Dictionary[int, EchoSnapshot]
## Last acknowledged [EchoSnapshot] sorted by client
var client_ack_snapshots: Dictionary[int, EchoSnapshot]
## Tick of last [EchoSnapshot] received by server
var last_received_snapshot_tick: int
## 8-bit Flag for each [EchoSnapshot] received prior to [member last_received_snapshot_tick]
var old_received_snapshots_flags: int
## Limit on stored snapshots
var max_stored_snapshots: int = 120

var last_frame_delta: float

## Initialize connection as Client-Server
func init_server() -> bool:
	if is_connected:
		push_warning("Cannot create connection whilst one is already open!")
		return false
	print("Initializing server...")
	_server_time = 0
	_tick = 0
	_next_tick_time = 0
	_next_input_tick_time = 0
	last_snapshot = null
	stored_snapshots.clear()
	client_ack_snapshots.clear()
	last_received_snapshot_tick = 0
	old_received_snapshots_flags = 0
	has_synced_time = true
	is_joinable = true
	_is_connected = true
	_is_server = true
	_is_client = true
	_server_peer = EchonetPeer.create_server()
	_server_peer.uid = Echonet.local_uid
	_server_peer.nickname = Echonet.local_nickname
	local_id = 1
	_client_peers = {1:server_peer}
	_connection_successful = false
	_has_peer_info = true
	_has_server_info = true
	call_deferred("_check_for_successful_connection")
	return true

## Initialize connection as a client joining a server
func init_client() -> bool:
	if is_connected:
		push_warning("Cannot create connection whilst one is already open!")
		return false
	print("Initializing client...")
	_server_time = 0
	_tick = 0
	_next_tick_time = 0
	_next_input_tick_time = 0
	last_snapshot = null
	stored_snapshots.clear()
	client_ack_snapshots.clear()
	last_received_snapshot_tick = 0
	old_received_snapshots_flags = 0
	has_synced_time = false
	_is_connected = true
	_is_client = true
	_client_peers = {}
	_connection_successful = false
	_has_peer_info = false
	_has_server_info = false
	call_deferred("_check_for_successful_connection")
	return true

## Initialize connection as Headless-Server
func init_headless_server() -> bool:
	if is_connected:
		push_warning("Cannot create connection whilst one is already open!")
		return false
	print("Initializing headless-server...")
	if FileAccess.file_exists("user://server_info.cfg"):
		print("Loading server_info.cfg...")
		var config := ConfigFile.new()
		if config.load("user://server_info.cfg") == OK:
			const SECTION_INFO := "info"
			const SECTION_SETTINGS := "settings"
			const SECTION_ENET := "enet"
			const SECTION_CLIENTS := "clients"
			server_name = config.get_value(SECTION_INFO, "name", server_name)
			max_peers = config.get_value(SECTION_SETTINGS, "maxpeers", max_peers)
			password = hash_password(config.get_value(SECTION_SETTINGS, "password", []))
			uid_whitelist = config.get_value(SECTION_CLIENTS, "whitelist", uid_whitelist)
			uid_blacklist = config.get_value(SECTION_CLIENTS, "blacklist", uid_blacklist)
			uid_admin_list = config.get_value(SECTION_CLIENTS, "admins", uid_admin_list)
			allow_empty_uid = !config.get_value(SECTION_SETTINGS, "requireuid", !allow_empty_uid)
			flags_to_ban = config.get_value(SECTION_SETTINGS, "flaglimit", flags_to_ban)
			tick_rate = config.get_value(SECTION_SETTINGS, "tickrate", tick_rate)
			if self is ENetTransport:
				self.port = config.get_value(SECTION_ENET, "port", self.port)
				self.ip = config.get_value(SECTION_ENET, "ip", self.ip)
		else: push_warning("Unable to read server_info.cfg")
	_server_time = 0
	_tick = 0
	_next_tick_time = 0
	_next_input_tick_time = 0
	last_snapshot = null
	stored_snapshots.clear()
	client_ack_snapshots.clear()
	last_received_snapshot_tick = 0
	old_received_snapshots_flags = 0
	has_synced_time = true
	is_joinable = true
	_is_connected = true
	_is_server = true
	_server_peer = EchonetPeer.create_server()
	local_id = 1
	_client_peers = {}
	_connection_successful = false
	_has_peer_info = true
	_has_server_info = true
	call_deferred("_check_for_successful_connection")
	return true

## Sends an info request to a server
func init_server_info_request() -> bool:
	if is_connected:
		push_warning("Cannot create connection whilst one is already open!")
		return false
	print("Sending server info request...")
	_is_connected = true
	_connection_successful = false
	_has_peer_info = false
	_has_server_info = false
	call_deferred("_check_for_successful_connection")
	return true

## Shutdown open connections
func shutdown(reason: DisconnectReason = DisconnectReason.LOCAL_REQUEST) -> bool:
	if !is_connected:
		push_warning("No connection to shutdown")
		return false
	if is_server:
		print("Shutdown server")
		if !is_client && FileAccess.file_exists("user://server_info.cfg"):
			print("Saving server_info.cfg...")
			var config := ConfigFile.new()
			if config.load("user://server_info.cfg") == OK:
				config.set_value("clients", "blacklist", uid_blacklist)
				config.set_value("clients", "admins", uid_admin_list)
				if config.save("user://server_info.cfg") != OK:
					push_warning("Unable to save server_info.cfg")
			else: push_warning("Unable to load server_info.cfg to save")
	else:
		match reason:
			DisconnectReason.ERROR:
				print("Disconnected due to error")
			DisconnectReason.UNKNOWN:
				print("Disconnected for unkown reason")
			DisconnectReason.LOCAL_REQUEST:
				print("Disconnected from server")
			DisconnectReason.TIMEOUT:
				print("Disconnected due to timeout")
			DisconnectReason.SERVER_CLOSING:
				print("Server shutdown, connection lost")
			DisconnectReason.KICKED:
				print("Kicked from server")
			DisconnectReason.LOST_CONNECTION:
				print("Lost connection to server")
			DisconnectReason.FAILED_AUTHENTICATION_PASSWORD:
				print("Incorrect password to connect to server")
			DisconnectReason.FAILED_AUTHENTICATION_HASH:
				print("Failed to pass authentication")
			DisconnectReason.FAILED_AUTHENTICATION_WHITELIST:
				print("Unable to connect-- server is whitelisted")
			DisconnectReason.SERVER_PRIVATE:
				print("Unable to connect-- server is rejecting new connections")
			DisconnectReason.FAILED_AUTHENTICATION_IDENTIFICATION:
				print("Failed to pass identity authentication")
			DisconnectReason.FAILED_AUTHENTICATION_BLACKLISTED:
				print("Disconnected due to server ban")
			DisconnectReason.SERVER_FULL:
				print("Failed to connect due to full server")
			DisconnectReason.INFO_REQUEST_COMPLETED:
				print("Info request completed-- Disconnecting")
			DisconnectReason.INFO_REQUEST_TIMEOUT:
				print("Info request timed out-- Disconnecting")
			DisconnectReason.FAILED_TO_VERIFY:
				print("Kicked due to failing to send authentication")
	_is_connected = false
	_is_server = false
	_is_client = false
	_connection_successful = false
	_has_peer_info = false
	_has_server_info = false
	_client_peers.clear()
	_server_peer = null
	local_id = -1
	uid_admin_list.clear()
	uid_blacklist.clear()
	uid_whitelist.clear()
	_server_time = 0
	last_snapshot = null
	stored_snapshots.clear()
	client_ack_snapshots.clear()
	last_received_snapshot_tick = 0
	old_received_snapshots_flags = 0
	_tick = 0
	has_synced_time = false
	on_disconnected.emit(reason)
	EchoScene.clear_scenes()
	_late_join_spawn_packets.clear()
	return true

## Async method to check if client / server connected successfuly before timing out
func _check_for_successful_connection() -> void:
	var timeout_time := Time.get_ticks_msec() + connection_timeout_msec
	while Time.get_ticks_msec() < timeout_time:
		if !is_connected: return
		if _connection_successful && _has_server_info && _has_peer_info && has_synced_time:
			print("Connected successfully!")
			if is_server: on_server_initialized.emit()
			if is_client: on_connected_to_server.emit()
			if is_server && is_client: on_peer_connected.emit(local_id)
			if !is_server && !is_client:
				shutdown(DisconnectReason.INFO_REQUEST_COMPLETED)
			return
		await Engine.get_main_loop().process_frame
	if !is_client && !is_server: shutdown(DisconnectReason.INFO_REQUEST_TIMEOUT)
	else: shutdown(DisconnectReason.TIMEOUT)

## Default password hashing using sha256
func hash_password(input: String) -> PackedByteArray:
	return input.sha256_buffer()

## Returns next unused client ID
func _get_available_id() -> int:
	var new_id: int = _peer_id_counter
	var has_looped: bool = false
	while client_peers.has(new_id):
		new_id += 1
		if new_id > MAX_PEERS:
			if has_looped:
				push_error("Overflow on Client IDs!!!")
				break
			new_id = 2
			has_looped = true
	_peer_id_counter = new_id + 1
	if _peer_id_counter > MAX_PEERS: _peer_id_counter = 2
	return new_id

## Call when new peer connects-- assigns peer ID if none assigned yet
func peer_connected(peer: EchonetPeer) -> void:
	_client_peers[peer.id] = peer
	if is_server:
		var _nicknames: Dictionary[int, String]
		var _uids: Dictionary[int, int]
		var _admins: PackedInt32Array
		for n in client_peers.keys():
			if !client_peers[n].nickname.is_empty():
				_nicknames[n] = client_peers[n].nickname
			if client_peers[n].uid != 0:
				_uids[n] = client_peers[n].uid
			if client_peers[n].is_admin:
				_admins.append(n)
		server_broadcast(IDAssignmentPacket.new(peer.id, client_peers.keys(), _nicknames, _uids, _admins), 
			ServerChannels.BACKEND)
		print("New connection: ", peer)
		if !peer.is_self: on_peer_connected.emit.call_deferred(peer.id)
		if is_server && !peer.is_self: _send_late_join_spawns(peer)
		client_ack_snapshots[peer.id] = get_base_snapshot()

## Call when peer disconnects
func peer_disconnected(peer_id: int) -> void:
	on_peer_disconnecting.emit(peer_id)
	if is_server: 
		server_broadcast(IDUnassignmentPacket.new(peer_id), ServerChannels.BACKEND)
		for object_id in client_peers.get(peer_id, EchonetPeer.placeholder()).owned_object_ids.duplicate():
			despawn(object_id)
		client_ack_snapshots.erase(peer_id)
	print("Lost connection: ", client_peers.get(peer_id, EchonetPeer.placeholder()))
	_client_peers.erase(peer_id)

## Called after a client joins to initialize any spawning
func _send_late_join_spawns(peer: EchonetPeer) -> void:
	for packet in _late_join_spawn_packets.values():
		server_message(peer, packet, ServerChannels.SPAWN, true)

## Should be called every frame
func handle_events() -> void: pass

## Should be called every frame
func handle_time(delta: float) -> void:
	last_frame_delta = delta
	if !has_synced_time: return
	_server_time += int(delta * 1000)
	if server_time > MAX_SERVER_TIME: 
		_server_time -= MAX_SERVER_TIME
		_next_tick_time -= MAX_SERVER_TIME
		_next_input_tick_time -= MAX_SERVER_TIME
	if server_time > _next_input_tick_time:
		_next_input_tick_time = server_time + msec_per_input_tick
		on_input_tick.emit(float(Time.get_ticks_usec() - _last_input_tick_time) / 1000000.0)
		collect_input()
		_last_input_tick_time = Time.get_ticks_usec()
	var simulated_ticks: int = 0
	before_tick_loop.emit()
	while server_time > _next_tick_time:
		_tick += 1
		_next_tick_time += msec_per_tick
		simulated_ticks += 1
		on_tick.emit(float(Time.get_ticks_usec() - _last_tick_time) / 1000000.0)
		collect_state()
		if !is_server:
			if stored_snapshots.has(tick): apply_snapshot(stored_snapshots[tick])
		stored_snapshots.erase(tick - max_stored_snapshots)
		_last_tick_time = Time.get_ticks_usec()
		if simulated_ticks > MAX_TICKS_PER_FRAME: break
	after_tick_loop.emit()

## Handles receiving of packets
func handle_packet(packet: EchonetPacket) -> void:
	on_packet_received.emit(packet)
	match packet.type:
		EchonetPacket.PacketType.ID_ASSIGNMENT:
			if is_server: return
			packet = IDAssignmentPacket.new_remote(packet)
			if local_id == -1:
				_has_peer_info = true
				local_id = packet.id
				for remote_id in packet.remote_ids:
					var client = EchonetPeer.create_client(remote_id)
					client.nickname = packet.nicknames.get(remote_id, "")
					client.uid = packet.uids.get(remote_id, 0)
					if packet.admins.has(remote_id): client.is_admin = true
					peer_connected(client)
			else:
				var client = EchonetPeer.create_client(packet.id)
				client.nickname = packet.nicknames.get(packet.id, "")
				client.uid = packet.uids.get(packet.id, 0)
				if packet.admins.has(packet.id): client.is_admin = true
				peer_connected(client)
		EchonetPacket.PacketType.ID_UNASSIGNMENT:
			if is_server: return
			packet = IDUnassignmentPacket.new_remote(packet)
			peer_disconnected(packet.id)
		EchonetPacket.PacketType.AUTHENTICATION:
			if !is_server: return
			packet = AuthenticationPacket.new_remote(packet)
			if password.size() > 0 && packet.password != password:
				processs_authentication(AuthenticationResult.FAILED_PASSWORD, packet)
			elif packet.auth_hash != authentication_hash:
				processs_authentication(AuthenticationResult.FAILED_HASH, packet)
			elif uid_whitelist.size() > 0 && !uid_whitelist.has(packet.uid):
				processs_authentication(AuthenticationResult.FAILED_WHITELIST, packet)
			elif packet.uid == 0 && allow_empty_uid == false:
				processs_authentication(AuthenticationResult.FAILED_TO_GIVE_UID, packet)
			elif uid_blacklist.has(packet.uid):
				processs_authentication(AuthenticationResult.FAILED_BLACKLISTED, packet)
			else:
				processs_authentication(AuthenticationResult.SUCCESS, packet)
		EchonetPacket.PacketType.SERVER_INFO:
			if is_server: return
			if !_connection_successful: _connection_successful = true
			_has_server_info = true
			packet = ServerInfoPacket.new_remote(packet)
			if !is_client:
				printt("Received server info: ",
					'"%s"'%packet.server_name, 
					"%s/%s"%[packet.current_peers, packet.max_peers], 
					packet.status_to_string())
				on_server_info_request_received.emit(packet)
				_connection_successful = false
				shutdown(DisconnectReason.INFO_REQUEST_COMPLETED)
				return
			server_name = packet.server_name
			_max_peers = packet.max_peers
			if packet.server_status == ServerInfoPacket.ServerStatus.NON_JOINABLE:
				is_joinable = false
			else: is_joinable = true
		EchonetPacket.PacketType.INFO_REQUEST:
			packet = InfoRequestPacket.new_remote(packet)
			if is_server:
				packet = InfoRequestPacket.new_remote(packet)
				if packet.request_type == InfoRequestPacket.RequestType.SERVER_INFO:
					send_server_info(packet)
			else:
				pass
		EchonetPacket.PacketType.CHAT:
			packet = ChatPacket.new_remote(packet)
			if is_server: server_relay_message(packet)
			else: 
				on_chat_received.emit(packet.text, client_peers.get(packet.original_sender_id, null))
		EchonetPacket.PacketType.ADMIN_UPDATE:
			packet = AdminUpdatePacket.new_remote(packet)
			if client_peers.has(packet.id): client_peers[packet.id].is_admin = packet.promotion
		EchonetPacket.PacketType.TIME_SYNC:
			if is_server:
				pass
			else:
				packet = TimeSyncPacket.new_remote(packet)
				if has_synced_time:
					var old_time := server_time
					var server_loops: int = packet.current_tick / (MAX_SERVER_TIME / msec_per_tick)
					_server_time = packet.time + get_server_latency()
					_server_time += MAX_SERVER_TIME * server_loops
					print("Time Sync received. Adjusted by %smsec"%(server_time - old_time))
					on_time_resynced.emit(server_time - old_time)
				else:
					_server_time = packet.time + get_server_latency()
					_tick_rate = packet.ticks_per_second
					_tick = server_time / msec_per_tick
					_next_tick_time = tick * msec_per_tick + msec_per_tick
					while packet.current_tick * msec_per_tick > MAX_SERVER_TIME:
						_server_time += MAX_SERVER_TIME
						_next_tick_time += MAX_SERVER_TIME
						_tick += MAX_SERVER_TIME / msec_per_tick
						packet.current_tick -= MAX_SERVER_TIME / msec_per_tick
					has_synced_time = true
		EchonetPacket.PacketType.SPAWN:
			packet = SpawnPacket.new_remote(packet)
			var scene: PackedScene = ResourceLoader.load(ResourceUID.get_id_path(packet.scene_uid))
			if scene == null: push_error("Spawning error loading resource uid %s"%packet.scene_uid)
			else:
				if packet.owner_id != 0:
					var spawn_attempt_timeout: int = Time.get_ticks_msec() + get_server_latency() * 1.5
					while !client_peers.has(packet.owner_id):
						if Time.get_ticks_msec() >= spawn_attempt_timeout: 
							push_warning("Spawning EchoScene with missing owner (id=%s)"%packet.owner_id )
							break
						await Engine.get_main_loop().process_frame
				_late_join_spawn_packets[packet.spawn_id] = packet
				var new_scene := scene.instantiate()
				var new_echo_scene := EchoScene.new(new_scene, packet.spawn_id, client_peers.get(packet.owner_id, null))
				EchoScene.add_scene(new_echo_scene)
				new_scene.set_meta("echoscene", new_echo_scene)
				if packet.owner_id != 0 && client_peers.has(packet.owner_id):
					client_peers[packet.owner_id].owned_object_ids.append(packet.owner_id)
				if new_scene.has_method("_on_spawn"): new_scene.call("_on_spawn", packet.args)
				Echonet.add_child(new_scene)
		EchonetPacket.PacketType.DESPAWN:
			packet = DespawnPacket.new_remote(packet)
			var despawn_attempt_timeout: int = Time.get_ticks_msec() + get_server_latency() * 1.5
			while !EchoScene.scenes.keys().has(packet.despawn_id):
				if Time.get_ticks_msec() >= despawn_attempt_timeout: break
				await Engine.get_main_loop().process_frame
			if EchoScene.scenes.keys().has(packet.despawn_id):
				_late_join_spawn_packets.erase(packet.despawn_id)
				var owner: EchonetPeer = EchoScene.scenes[packet.despawn_id].owner
				if owner != null && owner.owned_object_ids.has(packet.despawn_id):
					owner.owned_object_ids.remove_at(owner.owned_object_ids.find(packet.despawn_id))
				EchoScene.remove_scene(packet.despawn_id)
		EchonetPacket.PacketType.RPC:
			packet = RPCPacket.new_remote(packet)
			if is_server:
				if packet.channel != ServerChannels.MAIN || packet.channel != ServerChannels.MAIN_RELIABLE:
					packet.channel = ServerChannels.MAIN
				server_broadcast(packet, packet.channel, packet.channel == ServerChannels.MAIN_RELIABLE)
			if packet.channel == ServerChannels.MAIN_RELIABLE:
				var rpc_attempt_timeout: int = Time.get_ticks_msec() + get_server_latency() * 1.5
				while packet.echo_node == null:
					if Time.get_ticks_msec() >= rpc_attempt_timeout: break
					packet.attempt_to_decode_node()
					await Engine.get_main_loop().process_frame
			if packet.echo_node != null:
				packet.echo_node.receive_remote_call(packet.method, packet.args_data, packet.caller)
		EchonetPacket.PacketType.INPUT:
			packet = InputPacket.new_remote(packet)
			if is_server:
				decode_and_set_input(packet.input_data, packet.sender)
				var _last_snapshot := client_ack_snapshots.get(packet.sender.id, get_base_snapshot())
				var time_difference: int = server_time - packet.time
				if time_difference > MAX_TIME_DESYNC || time_difference < -MAX_TIME_DESYNC:
					server_message(packet.sender, 
						TimeSyncPacket.new(server_time, tick_rate, tick), 
						ServerChannels.BACKEND,
						false)
				#if packet.last_ack_tick > _last_snapshot.tick:
				#	client_ack_snapshots[packet.sender.id] = EchoSnapshot.layer_snapshots(_last_snapshot, stored_snapshots.get(packet.last_ack_tick, _last_snapshot))
		EchonetPacket.PacketType.STATE:
			packet = StatePacket.new_remote(packet)
			if is_client:
				if packet.tick >= tick - max_stored_snapshots:
					stored_snapshots[packet.tick] = EchoSnapshot.new_from_state_packet(packet)
					if packet.tick <= tick && last_snapshot != null && last_snapshot.tick < packet.tick:
						last_snapshot = stored_snapshots[packet.tick]
						apply_snapshot(last_snapshot)
				var received_ticks := flags_to_received_ticks(last_received_snapshot_tick, old_received_snapshots_flags)
				if packet.tick > last_received_snapshot_tick:
					last_received_snapshot_tick = packet.tick
					old_received_snapshots_flags = 0
					var i := -1
					for n in range(packet.tick - 8, packet.tick):
						i += 1
						if received_ticks.has(n):
							old_received_snapshots_flags = old_received_snapshots_flags | n
				elif last_received_snapshot_tick - packet.tick == 0: pass
				elif last_received_snapshot_tick - packet.tick <= 8:
					var flag := int(last_received_snapshot_tick - packet.tick)
					old_received_snapshots_flags = old_received_snapshots_flags | flag
		_:
			push_error("Unrecognized packet type: ", packet.type)

## Spawns an object and returns it's ID
func spawn(scene_uid: int, args := Array([]), owner: EchonetPeer = null) -> int:
	if !is_server: push_error("Only server can spawn objects")
	if !ResourceUID.has_id(scene_uid):
		push_error("Unknown resource uid to spawn: %s"%scene_uid)
		return -1
	var id := EchoScene.get_available_scene_id()
	var scene: PackedScene = ResourceLoader.load(ResourceUID.get_id_path(scene_uid))
	if scene == null: push_error("Spawning error loading resource uid %s"%scene_uid)
	else:
		var new_scene := scene.instantiate()
		var new_echo_scene := EchoScene.new(new_scene, id, owner)
		EchoScene.add_scene(new_echo_scene)
		new_scene.set_meta("echoscene", new_echo_scene)
		if owner != null:
			owner.owned_object_ids.append(id)
		if new_scene.has_method("_on_spawn"): new_scene.call("_on_spawn", args)
		Echonet.add_child(new_scene)
		server_broadcast(SpawnPacket.new(scene_uid, id, owner.id, args), ServerChannels.SPAWN, true)
		_late_join_spawn_packets[id] = SpawnPacket.new(scene_uid, id, owner.id, args)
	return id

## Despawns object
func despawn(object_id: int) -> void:
	if !EchoScene.scenes.has(object_id): push_warning("Cannot despawn non-existent object")
	else:
		if EchoScene.scenes.keys().has(object_id):
			var owner: EchonetPeer = EchoScene.scenes[object_id].owner
			if owner != null && owner.owned_object_ids.has(object_id):
				owner.owned_object_ids.remove_at(owner.owned_object_ids.find(object_id))
			EchoScene.remove_scene(object_id)
		_late_join_spawn_packets.erase(object_id)
		server_broadcast(DespawnPacket.new(object_id), ServerChannels.SPAWN, true)

## Returns latency in milliseconds from server
func get_server_latency() -> int: return 0

## Call to kick a peer
func kick(peer: EchonetPeer) -> void:
	if peer.is_server:
		push_warning("Cannot kick server")
		return
	if peer.uid != 0:
		if uid_flags.has(peer.uid): uid_flags[peer.uid] += 1
		else: uid_flags[peer.uid] = 1
		if uid_flags[peer.uid] >= flags_to_ban: uid_blacklist.append(peer.uid)

## Adds a flag to UID of peer, banning them if their flag count equals [member flags_to_ban]
func flag(peer: EchonetPeer) -> void:
	if peer.is_server:
		push_warning("Cannot flag server")
		return
	if peer.uid != 0:
		if uid_flags.has(peer.uid): uid_flags[peer.uid] += 1
		else: uid_flags[peer.uid] = 1
		if uid_flags[peer.uid] >= flags_to_ban: 
			uid_blacklist.append(peer.uid)
			kick(peer)
	else:
		print("Cannot flag '%s' as they have no UID"%peer)

## Server calls to broadcast to all clients
func server_broadcast(packet: EchonetPacket, channel: int = 0, reliable: bool = false): pass

## Server calls to send packet to specific client
func server_message(peer: EchonetPeer, packet: EchonetPacket, channel: int = 0, reliable: bool = false): pass

## Client calls to send packet to server
func client_message(packet: EchonetPacket, channel: int = 0, reliable: bool = false): pass

## Called by server when authentication packet is received
func processs_authentication(result: AuthenticationResult, packet: AuthenticationPacket) -> void: pass

## Called by server when server info is requested by non-client
func send_server_info(packet: EchonetPacket) -> void: pass

## Returns [ServerInfoPacket] with up-to-date info
func _create_server_info_packet() -> ServerInfoPacket:
	var status : ServerInfoPacket.ServerStatus = ServerInfoPacket.ServerStatus.OPEN
	if !is_joinable: status = ServerInfoPacket.ServerStatus.NON_JOINABLE
	elif uid_whitelist.size() > 0: status = ServerInfoPacket.ServerStatus.WHITELIST_ONLY
	var packet := ServerInfoPacket.new(server_name, client_peers.size(), max_peers, status)
	return packet

## Sends chat message over the network-- if [param audience] is null, sends to all
func send_chat(message: String, audience: EchonetPeer = null) -> void:
	var chat_packet := ChatPacket.new(0, local_id, message)
	if audience != null: chat_packet.receiver = audience.id
	if is_server:
		if message.begins_with("/"):
			if message.is_empty(): return
			var args: PackedStringArray = message.split(" ", false)
			var command: String = args[0].trim_prefix("/")
			args.remove_at(0)
			handle_server_command(command, args, server_peer)
			return
		if audience == null:
			server_broadcast(chat_packet, ServerChannels.CHAT, true)
		else:
			server_message(audience, chat_packet, ServerChannels.CHAT, true)
		on_chat_received.emit(message, server_peer)
	else:
		client_message(chat_packet, ServerChannels.CHAT, true)

## Server sends non-personal chat message to specific peer-- null to send to all
func send_server_chat(message: String, audience: EchonetPeer) -> void:
	if audience != null:
		var chat_packet := ChatPacket.new(audience.id, 0, message)
		if audience.is_server: on_chat_received.emit(chat_packet.text, null)
		else: server_message(audience, chat_packet, ServerChannels.CHAT, true)
	else:
		var chat_packet := ChatPacket.new(0, 0, message)
		on_chat_received.emit(chat_packet.text, null)
		server_broadcast(chat_packet, ServerChannels.CHAT, true)

## Relays received [ChatPacket] across server
func server_relay_message(packet: ChatPacket) -> void:
	packet.original_sender_id = packet.sender.id
	if packet.text.begins_with("/"):
		if packet.text.is_empty(): return
		var args: PackedStringArray = packet.text.split(" ", false)
		var command: String = args[0].trim_prefix("/")
		args.remove_at(0)
		handle_server_command(command, args, packet.sender)
		return
	if is_client && packet.receiver == local_id: 
		on_chat_received.emit(packet.text, packet.sender)
		return
	elif packet.receiver == 0: 
		on_chat_received.emit(packet.text, packet.sender)
		server_broadcast(packet, ServerChannels.CHAT, true)
	elif client_peers.has(packet.receiver): 
		server_message(client_peers[packet.receiver], packet, ServerChannels.CHAT, true)

## Called when server command is received
func handle_server_command(command: String, args: PackedStringArray, peer: EchonetPeer) -> void:
	print("%s sent command: %s (%s)"%[peer, command, args])
	match command:
		"whisper":
			if args.size() < 2:
				send_server_chat("Error: 'whisper' must include more arguments", peer)
				return
			var audience := get_client_by_nickname(args[0])
			if audience == null:
				send_server_chat("Error: '%s' could not be found to 'whisper'"%args[0], peer)
				return
			if audience.id == peer.id:
				send_server_chat("Error: cannot whisper self", peer)
				return
			args.remove_at(0)
			var message: String
			for arg in args:
				message += "%s "%arg
			message = message.trim_suffix(" ")
			var chat_packet := ChatPacket.new(audience.id, peer.id, "(whisper) %s"%message)
			if audience.is_self:
				on_chat_received.emit("(whisper) %s"%message, peer)
				var chat_ack_packet := ChatPacket.new(peer.id, peer.id, "(whisper) %s"%message)
				server_message(peer, chat_ack_packet, ServerChannels.CHAT, true)
			else:
				server_message(audience, chat_packet, ServerChannels.CHAT, true)
				var chat_ack_packet := ChatPacket.new(peer.id, peer.id, "(whisper) %s"%message)
				if is_server: on_chat_received.emit(chat_ack_packet.text, server_peer)
				else: server_message(peer, chat_ack_packet, ServerChannels.CHAT, true)
		"kick":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to kick peers", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'kick' must include argument", peer)
				return
			var target := get_client_by_nickname(args[0])
			if target == null:
				send_server_chat("Error: '%s' could not be found to 'kick'"%args[0], peer)
				return
			if target.is_self:
				send_server_chat("Error: Cannot 'kick' self", peer)
				return
			if target.is_server:
				send_server_chat("Error: Cannot 'kick' server", peer)
				return
			kick(target)
			send_server_chat("Kicking '%s'"%args[0], peer)
		"flag":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to flag peers", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'flag' must include argument", peer)
				return
			var target := get_client_by_nickname(args[0])
			if target == null:
				send_server_chat("Error: '%s' could not be found to 'flag'"%args[0], peer)
				return
			if target.is_self:
				send_server_chat("Error: Cannot 'flag' self", peer)
				return
			if target.is_server:
				send_server_chat("Error: Cannot 'flag' server", peer)
				return
			flag(target)
			send_server_chat("Flagging '%s'"%args[0], peer)
		"ban":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to ban peers", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'ban' must include argument", peer)
				return
			var target := get_client_by_nickname(args[0])
			if target == null:
				send_server_chat("Error: '%s' could not be found to 'ban'"%args[0], peer)
				return
			if target.is_self:
				send_server_chat("Error: Cannot 'ban' self", peer)
				return
			if target.is_server:
				send_server_chat("Error: Cannot 'ban' server", peer)
				return
			kick(target)
			send_server_chat("Banning '%s'"%args[0], peer)
			if target.uid != 0: uid_blacklist.append(target.uid)
		"promote":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to promote peers", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'promote' must include argument", peer)
				return
			var target := get_client_by_nickname(args[0])
			if target == null:
				send_server_chat("Error: '%s' could not be found to 'promote'"%args[0], peer)
				return
			if target.is_server:
				send_server_chat("Error: Cannot 'promote' server", peer)
				return
			if target.is_admin: 
				send_server_chat("Error: '%s' is already an admin"%args[0], peer)
				return
			update_admin_status(target, true)
			send_server_chat("Promoting '%s'"%args[0], null)
			send_server_chat("You are now an admin", target)
		"demote":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to demote peers", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'demote' must include argument", peer)
				return
			var target := get_client_by_nickname(args[0])
			if target == null:
				send_server_chat("Error: '%s' could not be found to 'demote'"%args[0], peer)
				return
			if target.is_server:
				send_server_chat("Error: Cannot 'demote' server", peer)
				return
			if !target.is_admin: 
				send_server_chat("Error: '%s' is already not an admin"%args[0], peer)
				return
			update_admin_status(target, false)
			send_server_chat("Demoting '%s'"%args[0], peer)
			send_server_chat("You are no longer an admin", null)
		"joinable":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to set joinable status", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'joinable' must include argument", peer)
				return
			match args[0]:
				"1": is_joinable = true
				"t": is_joinable = true
				"true": is_joinable = true
				"0": is_joinable = false
				"f": is_joinable = false
				"false": is_joinable = false
				_:
					send_server_chat("Error: '%s' unrecognized argument for 'joinable'"%args[0], peer)
					return
			if is_joinable: send_server_chat("Server is now set to joinable", null)
			else: send_server_chat("Server is now set to unjoinable", null)
		"server_name":
			if !peer.is_admin:
				send_server_chat("Error: Must be admin to set server name", peer)
				return
			if args.size() < 1:
				send_server_chat("Error: 'server_name' must include argument", peer)
				return
			var new_name: String
			for arg in args:
				new_name += "%s "%arg
			new_name = new_name.trim_suffix(" ")
			server_name = new_name
			send_server_chat("Server name updated to: %s"%server_name, null)
		_: 
			send_server_chat("'%s' command unrecognized"%command, peer)

## Returns first client with matching nickname-- return null if not found
func get_client_by_nickname(nickname: String) -> EchonetPeer:
	for client in client_peers.values():
		if client.nickname.to_lower() == nickname.to_lower(): return client
	return null

## Returns first client with matching UID-- return null if not found
func get_client_by_uid(uid: String) -> EchonetPeer:
	for client in client_peers.values():
		if client.uid == uid: return client
	return null

## Updates admin status of a peer
func update_admin_status(peer: EchonetPeer, promote: bool = true) -> void:
	peer.is_admin = promote
	var admin_update_packet := AdminUpdatePacket.new(peer.id, promote)
	if peer.uid != 0 && should_save_admin_status_changes:
		if promote:
			uid_admin_list.append(peer.uid)
		else:
			if uid_admin_list.has(peer.uid): uid_admin_list.remove_at(uid_admin_list.find(peer.id))
	server_broadcast(admin_update_packet, ServerChannels.BACKEND, true)

## Call at regular intervals to gather statistics in array
## 0:data in	1:data out	2:packets in	3:packets out	4:rtt	5:throttle	6:packet loss
func gather_statistics() -> PackedInt64Array: return [0,0,0,0,0,0,0]

## Calls an [EchoFunc] over the network
func remote_call(echo_node: EchoNode, method: StringName, args_data: PackedByteArray, reliable: bool) -> void:
	var packet := RPCPacket.new(echo_node, method, args_data, client_peers[local_id])
	var channel := ServerChannels.MAIN
	if reliable: channel = ServerChannels.MAIN_RELIABLE
	if is_server:
		server_broadcast(packet, channel, reliable)
	else:
		client_message(packet, channel, reliable)

## Collect input from all [EchoNode]
func collect_input() -> void:
	if is_server: return
	if !client_peers.has(local_id): return
	var input_data: PackedByteArray
	for n in client_peers[local_id].owned_object_ids:
		if !EchoScene.scenes.has(n): return
		input_data.append_array(EchoScene.scenes[n].get_encoded_input())
	client_message(
		InputPacket.new(input_data, last_received_snapshot_tick, old_received_snapshots_flags, tick, server_time),
		ServerChannels.MAIN, 
		false)

## Decodes received Input data
func decode_and_set_input(data: PackedByteArray, owner: EchonetPeer) -> void:
	if !is_server: return
	if !client_peers.has(local_id): return
	var position := 0
	while position < data.size():
		if EchoScene.scenes.has(data.decode_u16(position)):
			if EchoScene.scenes[data.decode_u16(position)].owner == owner:
				EchoScene.scenes[data.decode_u16(position)].decode_and_set_input(data.slice(position))
			position += EchoScene.scenes[data.decode_u16(position)].decode_input_data_length(data.slice(position))
		else: return

func collect_state() -> void:
	if !is_server: return
	var new_snapshot := EchoSnapshot.new()
	for n in EchoScene.scenes.keys():
		for i in EchoScene.scenes[n].echo_nodes.keys():
			new_snapshot.world_state[EchoScene.scenes[n].echo_nodes[i].get_combined_id()] = EchoScene.scenes[n].echo_nodes[i].get_encoded_state()
	last_snapshot = new_snapshot
	stored_snapshots[tick] = new_snapshot
	for n in client_peers:
		if client_peers[n].is_self: continue
		var delta_snapshot := EchoSnapshot.delta_snapshot(client_ack_snapshots.get(n, get_base_snapshot()), new_snapshot)
		server_message(client_peers[n], StatePacket.new(tick, delta_snapshot.get_state_data()))

func get_base_snapshot() -> EchoSnapshot:
	var base_snapshot := EchoSnapshot.new()
	for n in EchoScene.scenes.keys():
		for i in EchoScene.scenes[n].echo_nodes.keys():
			base_snapshot.world_state[EchoScene.scenes[n].echo_nodes[i].get_combined_id()] = EchoScene.scenes[n].echo_nodes[i].get_base_encoded_state()
	return base_snapshot

func apply_snapshot(snapshot: EchoSnapshot) -> void:
	last_snapshot = snapshot
	var scenes: Dictionary[int, PackedInt32Array]
	for n in snapshot.world_state.keys():
		if !EchoScene.scenes.has(EchoNode.get_scene_id_from_combined_id(n)): continue
		if !EchoScene.scenes[EchoNode.get_scene_id_from_combined_id(n)].echo_nodes.has(EchoNode.get_node_id_from_combined_id(n)): continue
		EchoScene.scenes[EchoNode.get_scene_id_from_combined_id(n)]\
			.echo_nodes[EchoNode.get_node_id_from_combined_id(n)]\
			.decode_and_set_state(snapshot.world_state[n])

func flags_to_received_ticks(last_tick: int, flags: int) -> PackedInt32Array:
	var output := PackedInt32Array([last_tick])
	var i: int = -1
	for n in range(last_tick - 8, last_tick):
		i += 1
		if n < 0: continue
		if flags & i == 0: continue
		output.append(n)
	return output
