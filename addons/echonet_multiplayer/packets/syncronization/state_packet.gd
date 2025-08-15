## Handles syncronizing world state
class_name StatePacket extends EchonetPacket

var tick: int
var state_data: PackedByteArray

func _init(_tick := 0, _state_data := PackedByteArray([])) -> void:
	type = PacketType.STATE
	state_data = _state_data
	tick = _tick

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> StatePacket:
	var output := StatePacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(5)
	data.encode_u32(1, tick)
	data.append_array(state_data)
	return data

func decode() -> void:
	super.decode()
	tick = data.decode_u32(1)
	state_data = data.slice(5)
