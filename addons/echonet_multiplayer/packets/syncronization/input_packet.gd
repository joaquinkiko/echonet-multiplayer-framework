## Handles client input syncing
class_name InputPacket extends EchonetPacket

var input_data: PackedByteArray
var tick: int
var last_ack_tick: int
var old_ack_ticks_flags: int

func _init(_input_data := PackedByteArray([]), _last_ack_tick := 0, _old_ack_ticks_flags := 0, _tick := 0) -> void:
	type = PacketType.INPUT
	input_data = _input_data
	last_ack_tick = _last_ack_tick
	old_ack_ticks_flags = _old_ack_ticks_flags
	tick = _tick


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> InputPacket:
	var output := InputPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(6)
	data.encode_u16(1, last_ack_tick)
	data.encode_u8(3, old_ack_ticks_flags)
	data.encode_u16(4, tick)
	data.append_array(input_data)
	return data

func decode() -> void:
	super.decode()
	last_ack_tick = data.decode_u16(1)
	old_ack_ticks_flags = data.decode_u8(3)
	tick = data.decode_u16(4)
	input_data = data.slice(6)
