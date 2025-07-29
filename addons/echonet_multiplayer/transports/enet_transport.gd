## ENet based implementation of [EchonetTransport]
class_name ENetTransport extends EchonetTransport

## Time for server to await authentication before kicking a peer
const SERVER_AUTHENTICATION_TIMEOUT := 1500

## Primary [ENetConnection] used by server and clients
var connection: ENetConnection

## [ENetPacketPeer] of the server-- only used by remote clients
var enet_server_peer: ENetPacketPeer

## Array of [ENetPacketPeer] still awaiting verification
var _unverified_enet_peers: Array[ENetPacketPeer] = []

## IP Address to connect to
var ip: String:
	get: return _ip
	set(value): 
		if value.is_valid_ip_address(): _ip = value
		else: push_error("'%s' is not valid IP Address"%value)
var _ip: String = "127.0.0.1"
## Port to connect to
var port: int:
	get: return _port
	set(value):
		if port > 65535:
			push_error("%s too high a value for port-- 65535 is maximum value"%value)
			return
		elif port < 0:
			push_error("%s too low for port-- must be between 0 and 65535"%value)
			return
		elif port <= 1024: push_warning("Port %s may cause issues-- preffer ports over 1024"%value)
		port = value
var _port: int = 42069

func init_server() -> bool:
	if !super.init_server(): return false
	connection = ENetConnection.new()
	var error := connection.create_host_bound(ip, port, max_peers, ServerChannels.MAX)
	if error:
		print("Failed: ", error_string(error))
		connection = null
		shutdown(DisconnectReason.ERROR)
		return false
	_connection_successful = true
	return true

func init_client() -> bool:
	if !super.init_client(): return false
	connection = ENetConnection.new()
	var error := connection.create_host()
	if error:
		print("Failed: ", error_string(error))
		connection = null
		shutdown(DisconnectReason.ERROR)
		return false
	enet_server_peer = connection.connect_to_host(ip, port)
	return true

func init_server_info_request() -> bool:
	if !super.init_server_info_request(): return false
	connection = ENetConnection.new()
	var error := connection.create_host()
	if error:
		print("Failed: ", error_string(error))
		connection = null
		shutdown(DisconnectReason.ERROR)
		return false
	enet_server_peer = connection.connect_to_host(ip, port)
	return true

func init_headless_server() -> bool:
	if !super.init_headless_server(): return false
	connection = ENetConnection.new()
	var error := connection.create_host_bound(ip, port, max_peers + 1, ServerChannels.MAX)
	if error:
		print("Failed: ", error_string(error))
		connection = null
		shutdown(DisconnectReason.ERROR)
		return false
	_connection_successful = true
	return true

func shutdown(reason: DisconnectReason = DisconnectReason.LOCAL_REQUEST) -> bool:
	var was_server: bool = is_server
	if !super.shutdown(reason): return false
	if was_server:
		if connection != null:
			for peer in connection.get_peers():
				peer.peer_disconnect(DisconnectReason.SERVER_CLOSING)
	else:
		if enet_server_peer.is_active():
			enet_server_peer.peer_disconnect(1)
	var timeout = Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < timeout: await Engine.get_main_loop().process_frame
	connection = null
	return true

func handle_events() -> void:
	if connection == null: return
	
	var packet_event: Array = connection.service()
	var event_type: ENetConnection.EventType = packet_event[0]
	while event_type != ENetConnection.EVENT_NONE:
		var peer: ENetPacketPeer = packet_event[1]
		match event_type:
			ENetConnection.EVENT_ERROR:
				push_warning("Packet resulted in unknown error!")
				return
			ENetConnection.EVENT_CONNECT:
				if is_server:
					_unverified_enet_peers.append(peer)
					server_authentication_timeout(peer)
				elif is_client:
					var auth_packet := AuthenticationPacket.new(
						Echonet.local_nickname,
						Echonet.local_uid,
						password, 
						authentication_hash
						)
					enet_server_peer.send(ServerChannels.BACKEND, auth_packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
				else:
					var info_request_packet := InfoRequestPacket.new(InfoRequestPacket.RequestType.SERVER_INFO)
					enet_server_peer.send(ServerChannels.BACKEND, info_request_packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
			ENetConnection.EVENT_DISCONNECT:
				if is_server:
					if peer.has_meta("id"):
						peer_disconnected(peer.get_meta("id"))
					else:
						_unverified_enet_peers.erase(peer)
				else:
					if is_connected: shutdown(packet_event[2])
					return
			ENetConnection.EVENT_RECEIVE:
				for n in peer.get_available_packet_count():
					var packet := EchonetPacket.new()
					if is_server:
						packet.sender = client_peers.get(peer.get_meta("id", -1), null)
						if packet.sender == null:
							packet.sender = EchonetPeer.new(_unverified_enet_peers.find(peer))
					else:
						packet.sender = server_peer
					packet.data = peer.get_packet()
					packet.decode()
					handle_packet(packet)
		packet_event = connection.service()
		event_type = packet_event[0]

func kick(peer: EchonetPeer) -> void:
	super.kick(peer)
	peer.get_meta("enet_peer").peer_disconnect(DisconnectReason.KICKED)

func server_broadcast(packet: EchonetPacket, channel: int = 0, reliable: bool = false):
	if reliable:
		connection.broadcast(channel, packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
	else:
		connection.broadcast(channel, packet.encode(), ENetPacketPeer.FLAG_UNSEQUENCED)

func server_message(peer: EchonetPeer, packet: EchonetPacket, channel: int = 0, reliable: bool = false):
	var enet_peer: ENetPacketPeer = peer.get_meta("enet_peer")
	if reliable:
		enet_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
	else:
		enet_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_UNSEQUENCED)

func client_message(packet: EchonetPacket, channel: int = 0, reliable: bool = false):
	if reliable:
		enet_server_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
	else:
		enet_server_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_UNSEQUENCED)

func processs_authentication(result: AuthenticationResult, packet: AuthenticationPacket) -> void:
	var peer: ENetPacketPeer = _unverified_enet_peers.get(packet.sender.id)
	if peer == null: return
	if !is_joinable: 
		peer.peer_disconnect(DisconnectReason.SERVER_PRIVATE)
		return
	if client_peers.size() >= max_peers:
		peer.peer_disconnect(DisconnectReason.SERVER_FULL)
		return
	match result:
		AuthenticationResult.FAILED_PASSWORD:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_PASSWORD)
		AuthenticationResult.FAILED_HASH:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_HASH)
		AuthenticationResult.FAILED_WHITELIST:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_WHITELIST)
		AuthenticationResult.FAILED_TO_GIVE_UID:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_IDENTIFICATION)
		AuthenticationResult.FAILED_BLACKLISTED:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_BLACKLISTED)
		AuthenticationResult.SUCCESS:
			var Echonet_peer := EchonetPeer.create_client(_get_available_id())
			if uid_admin_list.has(packet.uid):
				Echonet_peer.is_admin = true
			Echonet_peer.set_meta("enet_peer", peer)
			peer.set_meta("id", Echonet_peer.id)
			Echonet_peer.nickname = packet.nickname.replace(" ", "")
			var existing_nicknames: PackedStringArray
			for client in client_peers.values(): existing_nicknames.append(client.nickname.to_lower())
			if existing_nicknames.has(Echonet_peer.nickname.to_lower()):
				var suffix: int = 0
				var og_nickname := Echonet_peer.nickname
				while existing_nicknames.has(Echonet_peer.nickname.to_lower()):
					suffix += 1
					if og_nickname.length() + 2 + str(suffix).length() > 32:
						var overwrite := og_nickname.length() + 2 + str(suffix).length() - 32
						var ascii_buffer := og_nickname.to_ascii_buffer()
						ascii_buffer.resize(32 - overwrite)
						og_nickname = ascii_buffer.get_string_from_ascii()
					Echonet_peer.nickname = "%s(%s)"%[og_nickname, suffix]
					if Echonet_peer.nickname.length() > 32:
						var ascii_buffer := Echonet_peer.nickname.to_ascii_buffer()
						ascii_buffer.resize(32)
						Echonet_peer.nickname = ascii_buffer.get_string_from_ascii()
			Echonet_peer.uid = packet.uid
			peer_connected(Echonet_peer)
			server_message(Echonet_peer, _create_server_info_packet(), ServerChannels.BACKEND, true)
			_unverified_enet_peers.erase(peer)

func send_server_info(packet: EchonetPacket) -> void:
	var peer: ENetPacketPeer = _unverified_enet_peers.get(packet.sender.id)
	peer.send(ServerChannels.BACKEND, _create_server_info_packet().encode(), ENetPacketPeer.FLAG_RELIABLE)

func server_authentication_timeout(peer: ENetPacketPeer) -> void:
	var timeout_time := Time.get_ticks_msec() + SERVER_AUTHENTICATION_TIMEOUT
	while Time.get_ticks_msec() < timeout_time:
		if !_unverified_enet_peers.has(peer): return
		await Engine.get_main_loop().process_frame
	if peer != null: peer.peer_disconnect(DisconnectReason.FAILED_TO_VERIFY)

func gather_statistics() -> PackedInt64Array:
	if connection == null: return super.gather_statistics()
	var data := PackedInt64Array([0,0,0,0,0,0,0])
	data[0]  = int(connection.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA))
	data[1]  = int(connection.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA))
	data[2]  = int(connection.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS))
	data[3]  = int(connection.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS))
	if enet_server_peer != null && enet_server_peer.is_active():
		data[4] = int(enet_server_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
	else: data[4] = 0
	if enet_server_peer != null && enet_server_peer.is_active():
		data[5] = int(enet_server_peer.get_statistic(ENetPacketPeer.PEER_PACKET_THROTTLE) / 
			ENetPacketPeer.PACKET_THROTTLE_SCALE * 100)
	else: data[5] = 100
	if enet_server_peer != null && enet_server_peer.is_active():
		data[6] = int(enet_server_peer.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS) / 
			ENetPacketPeer.PACKET_LOSS_SCALE * 100)
	else: data[6] = 0
	return data
