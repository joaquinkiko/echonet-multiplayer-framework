## Handles info about client peers such as nicknames and UIDs
class_name PeerInfoPacket extends EchonetPacket

## Nicknames sorted by client id
var nicknames: Dictionary[int, String]
## UIDs sorted by client id
var uids: Dictionary[int, int]
## Sorted client ids of admin clients
var admins: Dictionary[int, bool]

func _init(_nicknames: Dictionary[int, String] = {}, _uids: Dictionary[int, int] = {}, _admins: Dictionary[int, bool] = {}) -> void:
	type = PacketType.PEER_INFO
	nicknames = _nicknames
	uids = _uids
	admins = _admins

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> PeerInfoPacket:
	var output := PeerInfoPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(2)
	# Encode
	data.encode_u8(1, nicknames.size())
	var pos: int
	for n in nicknames.keys():
		pos = data.size()
		data.resize(data.size() + 2)
		data.encode_u8(pos, n)
		pos += 1
		data.encode_u8(pos, nicknames[n].length())
		data.append_array(nicknames[n].to_ascii_buffer())
		pos = data.size()
		data.resize(data.size() + 1)
		if admins.has(n) && uids.has(n):
			data.encode_u8(pos, 3)
		elif admins.has(n):
			data.encode_u8(pos, 2)
		elif uids.has(n):
			data.encode_u8(pos, 1)
		else:
			data.encode_u8(pos, 0)
		if uids.has(n):
			data.resize(data.size() + 8)
			data.encode_u64(pos + 1, uids[n])
	return data

func decode() -> void:
	super.decode()
	# Decode
	var pos: int = 2
	for n in data.decode_u8(1):
		var id := data.decode_u8(pos)
		nicknames[id] = data.slice(pos + 2, data.decode_u8(pos + 1) + pos + 2).get_string_from_ascii()
		pos += data.decode_u8(pos + 1) + 2
		var flag := data.decode_u8(pos)
		if flag == 2 || flag == 3:
			admins[id] = true
		if flag == 1 || flag == 3:
			uids[id] = data.decode_u64(pos + 1)
			pos += 8
		pos += 1
