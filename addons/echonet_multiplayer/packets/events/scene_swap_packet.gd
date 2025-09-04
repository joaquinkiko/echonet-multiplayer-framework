## Handles swapping main scene
class_name SceneSwapPacket extends EchonetPacket

var scene_uid: int
var ack_code: int
var args: Array

func _init(_scene_uid := 0, _ack_code := 0, _args := Array([])) -> void:
	type = PacketType.SCENE_SWAP
	scene_uid = _scene_uid
	ack_code = _ack_code
	args = _args

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> SceneSwapPacket:
	var output := SceneSwapPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(14)
	data.encode_u64(1, scene_uid)
	data.encode_u32(9, ack_code)
	data.encode_u8(13, args.size())
	var pos := 14
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
	ack_code = data.decode_u32(9)
	args.resize(data.decode_u8(13))
	var pos := 14
	for n in args.size():
		args[n] = data.decode_var(pos, false)
		pos += data.decode_var_size(pos, false)
