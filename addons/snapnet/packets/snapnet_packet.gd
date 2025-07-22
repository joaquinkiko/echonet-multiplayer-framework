## Base class used by network packets
class_name SnapnetPacket extends RefCounted

## Packet signature with value from 0-255
enum PacketType {
	UNKNOWN = 0,
	ID_ASSIGNMENT = 1,
	ID_UNASSIGNMENT = 2,
	PEER_INFO = 3,
	SERVER_INFO = 4,
	AUTHENTICATION = 5,
	INFO_REQUEST = 6,
	CHAT = 7,
	ADMIN_UPDATE = 8,
}

## [PacketType] to sign first byte of packet with
var type: PacketType = PacketType.UNKNOWN

## [SnapnetPeer] that sent packet
var sender: SnapnetPeer

## Raw encoded data of packet
var data := PackedByteArray([])

## Decodes vars from [member data]
func decode() -> void:
	type = data.decode_u8(0)

## Encodes vars to [member data] before returning [member data]
func encode() -> PackedByteArray:
	data.resize(1)
	data.encode_u8(0, type)
	return data
