## Handles assigning IDs to newly connected peers
class_name IDAssignmentPacket extends EchonetPacket

## ID of newly connected peer
var id: int
## ID of already present peers
var remote_ids: PackedInt32Array

func _init(_id: int = -1, _remote_ids: PackedInt32Array = []) -> void:
	type = PacketType.ID_ASSIGNMENT
	id = _id
	remote_ids = _remote_ids

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> IDAssignmentPacket:
	var output := IDAssignmentPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(2 + remote_ids.size())
	data.encode_u8(1, id)
	for i in remote_ids.size():
		var id: int = remote_ids[i]
		data.encode_u8(2 + i, id)
	return data

func decode() -> void:
	super.decode()
	id = data.decode_u8(1)
	for i in range(2, data.size()):
		remote_ids.append(data.decode_u8(i))
