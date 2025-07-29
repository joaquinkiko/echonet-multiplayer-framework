## Handles 
class_name SpawnPacket extends EchonetPacket

var scene_uid: int
var spawn_id: int

func _init(_scene_uid := 0, _spawn_id := 0) -> void:
	type = PacketType.SPAWN
	scene_uid = _scene_uid
	spawn_id = _spawn_id

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> SpawnPacket:
	var output := SpawnPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(11)
	data.encode_u64(1, scene_uid)
	data.encode_u16(9, spawn_id)
	return data

func decode() -> void:
	super.decode()
	scene_uid = data.decode_u64(1)
	spawn_id = data.decode_u16(9)
