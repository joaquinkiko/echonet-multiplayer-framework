## Handles assigning IDs to newly connected peers
class_name IDAssignmentPacket extends EchonetPacket

## ID of newly connected peer
var id: int
## ID of already present peers
var remote_ids: PackedInt32Array

## Nicknames sorted by client id
var nicknames: Dictionary[int, String]
## UIDs sorted by client id
var uids: Dictionary[int, int]
## List of clients with admin status
var admins: PackedInt32Array

enum PeerFlags {
	NONE = 0,
	UID = 1,
	NICKNAME = 2,
	UID_NICKNAME = 3,
	ADMIN = 4,
	UID_ADMIN = 5,
	NICKNAME_ADMIN = 6,
	UID_NICKNAME_ADMIN = 7
}

func _init(_id := -1, _remote_ids  := PackedInt32Array([]), _nicknames: Dictionary[int, String] = {}, _uids: Dictionary[int, int] = {}, _admins := PackedInt32Array([])) -> void:
	type = PacketType.ID_ASSIGNMENT
	id = _id
	remote_ids = _remote_ids
	nicknames = _nicknames
	uids = _uids
	admins = _admins

## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> IDAssignmentPacket:
	var output := IDAssignmentPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(3)
	data.encode_u8(1, id)
	data.encode_u8(2, remote_ids.size())
	for n in remote_ids:
		data.resize(data.size() + 2)
		data.encode_u8(data.size() - 2, n)
		if nicknames.has(n) && uids.has(n) && admins.has(n):
			data.encode_u8(data.size() -1, PeerFlags.UID_NICKNAME_ADMIN)
		elif nicknames.has(n) && uids.has(n):
			data.encode_u8(data.size() -1, PeerFlags.UID_NICKNAME)
		elif nicknames.has(n) && admins.has(n):
			data.encode_u8(data.size() -1, PeerFlags.NICKNAME_ADMIN)
		elif uids.has(n) && admins.has(n):
			data.encode_u8(data.size() -1, PeerFlags.UID_ADMIN)
		elif nicknames.has(n):
			data.encode_u8(data.size() -1, PeerFlags.NICKNAME)
		elif uids.has(n):
			data.encode_u8(data.size() -1, PeerFlags.UID)
		elif admins.has(n):
			data.encode_u8(data.size() -1, PeerFlags.ADMIN)
		else:
			data.encode_u8(data.size() -1, PeerFlags.NONE)
		var flag := data.decode_u8(data.size() - 1)
		if flag == PeerFlags.NICKNAME  || flag == PeerFlags.UID_NICKNAME \
		|| flag == PeerFlags.NICKNAME_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
			data.resize(data.size() + 1)
			data.encode_u8(data.size() - 1, nicknames[n].length())
			data.append_array(nicknames[n].to_ascii_buffer())
		if flag == PeerFlags.UID  || flag == PeerFlags.UID_NICKNAME \
		|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
			data.resize(data.size() + 1)
			data.encode_u8(data.size() - 1, uids[n])
	return data
	#data.resize(data.size() + 1)
	#if nicknames.has(id) && uids.has(id) && admins.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.UID_NICKNAME_ADMIN)
	#elif nicknames.has(id) && uids.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.UID_NICKNAME)
	#elif nicknames.has(id) && admins.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.NICKNAME_ADMIN)
	#elif uids.has(id) && admins.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.UID_ADMIN)
	#elif nicknames.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.NICKNAME)
	#elif uids.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.UID)
	#elif admins.has(id):
	#	data.encode_u8(data.size() -1, PeerFlags.ADMIN)
	#else:
	#	data.encode_u8(data.size() -1, PeerFlags.NONE)
	#var flag := data.decode_u8(data.size() - 1)
	#if flag == PeerFlags.NICKNAME  || flag == PeerFlags.UID_NICKNAME \
	#|| flag == PeerFlags.NICKNAME_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
	#	data.resize(data.size() + 1)
	#	data.encode_u8(data.size() - 1, nicknames[id].length())
	#	data.append_array(nicknames[id].to_ascii_buffer())
	#if flag == PeerFlags.UID  || flag == PeerFlags.UID_NICKNAME \
	#|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
	#	data.resize(data.size() + 1)
	#	data.encode_u8(data.size() - 1, uids[id])
	#return data
	#data.resize(2 + remote_ids.size())
	#data.encode_u8(1, id)
	#for i in remote_ids.size():
	#	var id: int = remote_ids[i]
	#	data.encode_u8(2 + i, id)
	#return data

func decode() -> void:
	super.decode()
	id = data.decode_u8(1)
	var pos := 3
	for n in data.decode_u8(2):
		var remote_id := data.decode_u8(pos)
		remote_ids.append(remote_id)
		pos += 1
		var flag: PeerFlags = data.decode_u8(pos)
		if flag == PeerFlags.ADMIN  || flag == PeerFlags.NICKNAME_ADMIN \
		|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
			admins.append(remote_id)
		if flag == PeerFlags.NICKNAME  || flag == PeerFlags.UID_NICKNAME \
		|| flag == PeerFlags.NICKNAME_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
			pos += 1
			nicknames[remote_id] = data.slice(pos + 1, pos + 1 + data.decode_u8(pos)).get_string_from_ascii()
			pos += 1 + data.decode_u8(pos)
		if flag == PeerFlags.UID  || flag == PeerFlags.UID_NICKNAME \
		|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
			uids[remote_id] = data.decode_u8(pos)
			pos += 1
	#var flag: PeerFlags = data.decode_u8(pos)
	#if flag == PeerFlags.ADMIN  || flag == PeerFlags.NICKNAME_ADMIN \
	#|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
	#	admins.append(id)
	#if flag == PeerFlags.NICKNAME  || flag == PeerFlags.UID_NICKNAME \
	#|| flag == PeerFlags.NICKNAME_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
	#	pos += 1
	#	nicknames[id] = data.slice(pos + 1, pos + 1 + data.decode_u8(pos)).get_string_from_ascii()
	#	pos += 1 + data.decode_u8(pos)
	#if flag == PeerFlags.UID  || flag == PeerFlags.UID_NICKNAME \
	#|| flag == PeerFlags.UID_ADMIN || flag == PeerFlags.UID_NICKNAME_ADMIN:
	#	uids[id] = data.decode_u8(pos)
	#	pos += 1
	##
	#id = data.decode_u8(1)
	#for i in range(2, data.size()):
	#	remote_ids.append(data.decode_u8(i))
