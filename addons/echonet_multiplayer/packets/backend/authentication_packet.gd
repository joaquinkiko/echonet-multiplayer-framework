## Handles authentication data when client first connects to server
class_name AuthenticationPacket extends EchonetPacket

## Peer's nickname
var nickname: String
## Peer's local uid
var uid: int
## Peer's password to compare with server
var password: PackedByteArray
## Peer's authentication hash (i.e. game version, active mod list) to compare with server
var auth_hash: PackedByteArray

func _init(_nickname := "", _uid := 0, _password := PackedByteArray([]), _auth_hash := PackedByteArray([])) -> void:
	type = PacketType.AUTHENTICATION
	nickname = _nickname
	if nickname.length() > Echonet.MAX_NICKNAME_SIZE:
		nickname = nickname.to_ascii_buffer().slice(0, Echonet.MAX_NICKNAME_SIZE - 1).get_string_from_ascii()
	uid = _uid
	password = _password
	auth_hash = _auth_hash

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> AuthenticationPacket:
	var output := AuthenticationPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(2)
	data.encode_u8(1, nickname.length())
	data.append_array(nickname.to_ascii_buffer())
	data.resize(data.size() + 8)
	data.encode_u64(data.size() - 8, uid)
	data.resize(data.size() + 1)
	data.encode_u8(data.size() - 1, password.size())
	data.append_array(password)
	data.resize(data.size() + 1)
	data.encode_u8(data.size() - 1, auth_hash.size())
	data.append_array(auth_hash)
	return data

func decode() -> void:
	super.decode()
	var nickname_size: int
	var password_size: int
	var auth_hash_size: int
	var password_pos: int
	var auth_hash_pos: int
	nickname_size = data.decode_u8(1)
	password_pos = 11 + nickname_size
	password_size = data.decode_u8(10 + nickname_size)
	auth_hash_pos = 12 + nickname_size + password_size
	auth_hash_size = data.decode_u8(11 + nickname_size + password_size)
	
	if nickname_size > 0:
		nickname = data.slice(2, 2 + nickname_size).get_string_from_ascii()
	else: nickname = ""
	uid = data.decode_u64(2 + nickname_size)
	if password_size > 0:
		password = data.slice(password_pos, password_pos + password_size)
	else: password = []
	if auth_hash_size > 0:
		auth_hash = data.slice(auth_hash_pos, auth_hash_pos + auth_hash_size)
	else: auth_hash = []
