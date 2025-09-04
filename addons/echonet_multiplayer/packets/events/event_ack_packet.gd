## Handles acknowledging completion of events
class_name EventAckPacket extends EchonetPacket

var ack_code: int

func _init(_ack_code := 0) -> void:
	type = PacketType.EVENT_ACK
	ack_code = _ack_code


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> EventAckPacket:
	var output := EventAckPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(5)
	data.encode_u32(1, ack_code)
	return data

func decode() -> void:
	super.decode()
	ack_code = data.decode_u32(1)
