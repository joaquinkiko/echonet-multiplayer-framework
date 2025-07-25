## Handles notifying of client promotions and demotions
class_name AdminUpdatePacket extends SnapnetPacket

var id: int
var promotion: bool

func _init(_id: int = 0, _promotion: bool = true) -> void:
	type = PacketType.ADMIN_UPDATE
	id = _id
	promotion = _promotion

## Transforms generic [SnapnetPacket] for use after being received from remote peer
static func new_remote(packet: SnapnetPacket) -> AdminUpdatePacket:
	var output := AdminUpdatePacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(3)
	# Encode
	data.encode_u8(1, id)
	data.encode_u8(2, int(promotion))
	return data

func decode() -> void:
	super.decode()
	# Decode
	id = data.decode_u8(1)
	promotion = data[2] == 1
