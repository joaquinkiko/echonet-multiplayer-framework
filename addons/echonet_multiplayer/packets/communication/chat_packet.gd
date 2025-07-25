## Handles delivering chat messages.
## Uses GZip compression on chat messages.
class_name ChatPacket extends EchonetPacket

## Max size of chat message, excess will be trimmed
const MAX_CHAT_SIZE := 255

## Chat contents
var text: String
## Client ID of receiver-- 0 if meant for all clients
var receiver: int
## Client ID of sender-- 0 if sent by server backend
var original_sender_id: int

func _init(_receiver := 0, _original_sender_id := 0, _text := "") -> void:
	type = PacketType.CHAT
	receiver = _receiver
	original_sender_id = _original_sender_id
	text = _text

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> ChatPacket:
	var output := ChatPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(4)
	data.encode_u8(2, original_sender_id)
	data.encode_u8(1, receiver)
	var compressed_text: PackedByteArray 
	if text.length() > MAX_CHAT_SIZE:
		var text_buffer := text.to_ascii_buffer()
		text_buffer.resize(MAX_CHAT_SIZE)
		text = text_buffer.get_string_from_ascii()
	compressed_text = text.to_ascii_buffer().compress(FileAccess.COMPRESSION_GZIP)
	data.encode_u8(3, text.length())
	data.append_array(compressed_text)
	return data

func decode() -> void:
	super.decode()
	receiver = data.decode_u8(1)
	original_sender_id = data.decode_u8(2)
	if data.decode_u8(3) > 0:
		text = data.slice(4).decompress(data.decode_u8(3), FileAccess.COMPRESSION_GZIP).get_string_from_ascii()
