## Handles client input syncing
class_name InputPacket extends EchonetPacket

var input_data: PackedByteArray

func _init(_input_data := PackedByteArray([])) -> void:
	type = PacketType.INPUT
	input_data = _input_data


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> InputPacket:
	var output := InputPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.append_array(input_data)
	return data

func decode() -> void:
	super.decode()
	input_data = data.slice(1)
