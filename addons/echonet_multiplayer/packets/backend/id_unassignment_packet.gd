## Handles notifying of disconnected peers
class_name IDUnassignmentPacket extends EchonetPacket

## ID of disconnected peer
var id: int

func _init(_id: int = -1) -> void:
	type = PacketType.ID_UNASSIGNMENT
	id = _id

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> IDUnassignmentPacket:
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
