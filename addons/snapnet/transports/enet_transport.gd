## ENet based implementation of [SnapnetTransport]
class_name ENetTransport extends SnapnetTransport

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
	var error := connection.create_host_bound(ip, port, max_peers - 1, MAX_CHANNELS)
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
	var error := connection.create_host_bound(ip, port, max_peers, MAX_CHANNELS)
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
						Snapnet.local_nickname,
						Snapnet.local_uid,
						password, 
						authentication_hash
						)
					enet_server_peer.send(0, auth_packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
				else:
					var info_request_packet := InfoRequestPacket.new(InfoRequestPacket.RequestType.SERVER_INFO)
					enet_server_peer.send(0, info_request_packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
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
				if is_server:
					var packet := SnapnetPacket.new()
					packet.sender = client_peers.get(peer.get_meta("id", -1), null)
					if packet.sender == null:
						packet.sender = SnapnetPeer.new(_unverified_enet_peers.find(peer))
					packet.data = peer.get_packet()
					packet.decode()
					handle_packet(packet)
				else:
					var packet := SnapnetPacket.new()
					packet.sender = server_peer
					packet.data = peer.get_packet()
					packet.decode()
					handle_packet(packet)
		packet_event = connection.service()
		event_type = packet_event[0]

func kick(peer: SnapnetPeer) -> void:
	peer.get_meta("enet_peer").peer_disconnect(DisconnectReason.KICKED)

func server_broadcast(packet: SnapnetPacket, channel: int = 0, reliable: bool = false):
	if reliable:
		connection.broadcast(channel, packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
	else:
		connection.broadcast(channel, packet.encode(), ENetPacketPeer.FLAG_UNSEQUENCED)

func server_message(peer: SnapnetPeer, packet: SnapnetPacket, channel: int = 0, reliable: bool = false):
	var enet_peer: ENetPacketPeer = peer.get_meta("enet_peer")
	if reliable:
		enet_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_RELIABLE)
	else:
		enet_peer.send(channel, packet.encode(), ENetPacketPeer.FLAG_UNSEQUENCED)

func client_message(packet: SnapnetPacket, channel: int = 0, reliable: bool = false):
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
	match result:
		AuthenticationResult.FAILED_PASSWORD:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_PASSWORD)
		AuthenticationResult.FAILED_HASH:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_HASH)
		AuthenticationResult.FAILED_WHITELIST:
			peer.peer_disconnect(DisconnectReason.FAILED_AUTHENTICATION_WHITELIST)
		AuthenticationResult.SUCCESS:
			var snapnet_peer := SnapnetPeer.create_client(_get_available_id())
			snapnet_peer.set_meta("enet_peer", peer)
			peer.set_meta("id", snapnet_peer.id)
			snapnet_peer.nickname = packet.nickname
			snapnet_peer.uid = packet.uid
			peer_connected(snapnet_peer)
			server_message(snapnet_peer, _create_server_info_packet(), 0, true)
			var nickname_dict: Dictionary[int, String]
			var uid_dict: Dictionary[int, int]
			var admin_dict: Dictionary[int, bool]
			for n in client_peers.keys():
				nickname_dict[n] = client_peers[n].nickname
				if client_peers[n].uid != 0:
					uid_dict[n] = client_peers[n].uid
				if client_peers[n].is_admin:
					admin_dict[n] = true
			var peer_info_packet := PeerInfoPacket.new(nickname_dict, uid_dict, admin_dict)
			_unverified_enet_peers.erase(peer)
			server_broadcast(peer_info_packet, 0, true)

func send_server_info(packet: SnapnetPacket) -> void:
	var peer: ENetPacketPeer = _unverified_enet_peers.get(packet.sender.id)
	peer.send(0, _create_server_info_packet().encode(), ENetPacketPeer.FLAG_RELIABLE)

func server_authentication_timeout(peer: ENetPacketPeer) -> void:
	var timeout_time := Time.get_ticks_msec() + SERVER_AUTHENTICATION_TIMEOUT
	while Time.get_ticks_msec() < timeout_time:
		if !_unverified_enet_peers.has(peer): return
		await Engine.get_main_loop().process_frame
	if peer != null: peer.peer_disconnect(DisconnectReason.KICKED)
