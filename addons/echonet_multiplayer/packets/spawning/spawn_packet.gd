## Handles 
class_name SpawnPacket extends EchonetPacket

var scene_uid: int
var spawn_id: int
var owner_id: int
var args: Array

func _init(_scene_uid := 0, _spawn_id := 0, _owner_id := 0, _args := Array([])) -> void:
	type = PacketType.SPAWN
	scene_uid = _scene_uid
	spawn_id = _spawn_id
	owner_id = _owner_id
	args = _args

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> SpawnPacket:
	var output := SpawnPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(13)
	data.encode_u64(1, scene_uid)
	data.encode_u16(9, spawn_id)
	data.encode_u8(11, owner_id)
	data.encode_u8(12, args.size())
	var pos := 13
	for n in args.size():
		var raw_var: PackedByteArray
		raw_var.resize(256)
		raw_var.encode_var(0, args[n], false)
		var var_size := raw_var.decode_var_size(0, false)
		if var_size > 0:
			data.resize(data.size() + var_size)
			data.encode_var(pos, args[n], false)
			pos += var_size
	return data

func decode() -> void:
	super.decode()
	scene_uid = data.decode_u64(1)
	spawn_id = data.decode_u16(9)
	owner_id = data.decode_u8(11)
	args.resize(data.decode_u8(12))
	var pos := 13
	for n in args.size():
		args[n] = data.decode_var(pos, false)
		pos += data.decode_var_size(pos, false)
