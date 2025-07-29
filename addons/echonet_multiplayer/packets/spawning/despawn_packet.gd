## Handles 
class_name DespawnPacket extends EchonetPacket

var despawn_id: int

func _init(_despawn_id := 0) -> void:
	type = PacketType.DESPAWN
	despawn_id = _despawn_id


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> DespawnPacket:
	var output := DespawnPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(3)
	data.encode_u16(1,despawn_id)
	return data

func decode() -> void:
	super.decode()
	despawn_id = data.decode_u16(1)
