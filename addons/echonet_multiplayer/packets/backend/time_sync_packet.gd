## Handles syncronizing time between server and client
class_name TimeSyncPacket extends EchonetPacket

var time: int
var ticks_per_second: int

func _init(_time: int = 0, _ticks_per_second: int = 0) -> void:
	type = PacketType.TIME_SYNC
	time = _time
	ticks_per_second = _ticks_per_second


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> TimeSyncPacket:
	var output := TimeSyncPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(6)
	data.encode_u32(1, time)
	data.encode_u8(5, ticks_per_second)
	return data

func decode() -> void:
	super.decode()
	time = data.decode_u32(1)
	ticks_per_second = data.decode_u8(5)
