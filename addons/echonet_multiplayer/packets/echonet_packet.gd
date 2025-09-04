## Base class used by network packets
class_name EchonetPacket extends RefCounted

## Packet signature with value from 0-255
enum PacketType {
	UNKNOWN = 0,
	ID_ASSIGNMENT = 1,
	ID_UNASSIGNMENT = 2,
	SERVER_INFO = 3,
	AUTHENTICATION = 4,
	INFO_REQUEST = 5,
	CHAT = 6,
	ADMIN_UPDATE = 7,
	TIME_SYNC = 8,
	SPAWN = 9,
	DESPAWN = 10,
	RPC = 11,
	INPUT = 12,
	STATE = 13,
	SCENE_SWAP = 14,
	EVENT_ACK = 15,
}

## [PacketType] to sign first byte of packet with
var type: PacketType = PacketType.UNKNOWN

## [EchonetPeer] that sent packet
var sender: EchonetPeer

## Raw encoded data of packet
var data := PackedByteArray([])

## Channel data was sent over
var channel: EchonetTransport.ServerChannels

## Decodes vars from [member data]
func decode() -> void:
	type = data.decode_u8(0)

## Encodes vars to [member data] before returning [member data]
func encode() -> PackedByteArray:
	data.resize(1)
	data.encode_u8(0, type)
	return data
