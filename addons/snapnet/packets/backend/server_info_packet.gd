## Handles delivering info about the server
class_name ServerInfoPacket extends SnapnetPacket

## Current status of server
enum ServerStatus {
	OPEN = 0,
	NON_JOINABLE = 1,
	WHITELIST_ONLY = 2,
}

## Name of server
var server_name: String
## Current cients in server
var current_peers: int
## Max clients allowed in server
var max_peers: int
## Current [ServerStatus]
var server_status: ServerStatus

func _init(_server_name := "", _current_peers := 0, _max_peers := 0, _server_status := ServerStatus.OPEN) -> void:
	type = PacketType.SERVER_INFO
	server_name = _server_name
	current_peers = _current_peers
	max_peers = _max_peers
	server_status = _server_status

## Transforms generic [SnapnetPacket] for use after being received from remote peer
static func new_remote(packet: SnapnetPacket) -> ServerInfoPacket:
	var output := ServerInfoPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(4)
	# Encode
	data.encode_u8(1, server_status)
	data.encode_u8(2, current_peers)
	data.encode_u8(3, max_peers)
	data.append_array(server_name.to_ascii_buffer())
	return data

func decode() -> void:
	super.decode()
	# Decode
	server_status = data.decode_u8(1)
	current_peers = data.decode_u8(2)
	max_peers = data.decode_u8(3)
	server_name = data.slice(4).get_string_from_ascii()

func status_to_string() -> String:
	match server_status:
		ServerStatus.OPEN: return "Open"
		ServerStatus.NON_JOINABLE: return "Non-Joinable"
		ServerStatus.WHITELIST_ONLY: return "Whitelisted"
		_: return "Unknown"
