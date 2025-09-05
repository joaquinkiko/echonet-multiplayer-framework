## Handles delivering info about the server
class_name ServerInfoPacket extends EchonetPacket

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

var current_scene_uid: int
var current_scene_args: Array

func _init(_server_name := "", _current_peers := 0, _max_peers := 0, _server_status := ServerStatus.OPEN, _current_scene_uid := 0, _current_scene_args := Array([])) -> void:
	type = PacketType.SERVER_INFO
	server_name = _server_name
	current_peers = _current_peers
	max_peers = _max_peers
	server_status = _server_status
	current_scene_uid = _current_scene_uid
	current_scene_args = _current_scene_args

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> ServerInfoPacket:
	var output := ServerInfoPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(5)
	# Encode
	data.encode_u8(1, server_status)
	data.encode_u8(2, current_peers)
	data.encode_u8(3, max_peers)
	data.encode_u8(4,server_name.length())
	data.append_array(server_name.to_ascii_buffer())
	var position := 5 + server_name.length()
	data.resize(position + 9)
	data.encode_u64(position, current_scene_uid)
	data.encode_u8(position + 8, current_scene_args.size())
	var pos := position + 9
	for n in current_scene_args.size():
		var raw_var: PackedByteArray
		raw_var.resize(256)
		raw_var.encode_var(0, current_scene_args[n], false)
		var var_size := raw_var.decode_var_size(0, false)
		if var_size > 0:
			data.resize(data.size() + var_size)
			data.encode_var(pos, current_scene_args[n], false)
			pos += var_size
	return data

func decode() -> void:
	super.decode()
	# Decode
	server_status = data.decode_u8(1)
	current_peers = data.decode_u8(2)
	max_peers = data.decode_u8(3)
	var name_length := data.decode_u8(4)
	var position := 5 + name_length
	if name_length > 0: server_name = data.slice(5, position).get_string_from_ascii()
	current_scene_uid = data.decode_u64(position)
	current_scene_args.resize(data.decode_u8(position + 8))
	var pos := position + 9
	for n in current_scene_args.size():
		current_scene_args[n] = data.decode_var(pos, false)
		pos += data.decode_var_size(pos, false)

func status_to_string() -> String:
	match server_status:
		ServerStatus.OPEN: return "Open"
		ServerStatus.NON_JOINABLE: return "Non-Joinable"
		ServerStatus.WHITELIST_ONLY: return "Whitelisted"
		_: return "Unknown"
