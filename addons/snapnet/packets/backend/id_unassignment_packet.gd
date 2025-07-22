## Handles notifying of disconnected peers
class_name IDUnassignmentPacket extends SnapnetPacket

## ID of disconnected peer
var id: int

func _init(_id: int = -1) -> void:
	type = PacketType.ID_UNASSIGNMENT
	id = _id

## Transforms generic [SnapnetPacket] for use after being received from remote peer
static func new_remote(packet: SnapnetPacket) -> IDUnassignmentPacket:
	var output := IDUnassignmentPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(2)
	data.encode_u8(1, id)
	return data

func decode() -> void:
	super.decode()
	id = data.decode_u8(1)
