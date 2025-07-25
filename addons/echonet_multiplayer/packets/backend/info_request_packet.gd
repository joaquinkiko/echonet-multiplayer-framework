## Handles making special requests for data from the server
class_name InfoRequestPacket extends SnapnetPacket

## Type of data being requested
enum RequestType {
	SERVER_INFO = 1,
}

## Defines [RequestType] to sign packet with
var request_type: RequestType

func _init(_request_type := RequestType.SERVER_INFO) -> void:
	type = PacketType.INFO_REQUEST
	request_type = _request_type

## Transforms generic [SnapnetPacket] for use after being received from remote peer
static func new_remote(packet: SnapnetPacket) -> InfoRequestPacket:
	var output := InfoRequestPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(2)
	data.encode_u8(1, request_type)
	return data

func decode() -> void:
	super.decode()
	request_type = data.decode_u8(1)
