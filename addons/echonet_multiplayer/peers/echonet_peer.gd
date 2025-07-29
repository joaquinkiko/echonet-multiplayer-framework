## Represents a currently connected client
class_name EchonetPeer extends RefCounted

## Client ID on server-- Server will always be 1
var id: int:
	get: return _id
	set(value): push_error("'id' cannot be set directly")
var _id: int = -1
## Returns true if this client is also the server
var is_server: bool:
	get: return id == 1
	set(value): push_error("'is_server' cannot be set directly")
## Returns true if this is the local client
var is_self: bool:
	get: return Echonet.transport.local_id == id
	set(value): push_error("'is_self' cannot be set directly")

## Nickname of client
var nickname: String = ""
## UID of client
var uid: int = -1
## Returns true if client is a server admin (client-server will always return true)
var is_admin: bool:
	get: 
		if is_server: return true
		return _is_admin
	set(value): _is_admin = value
var _is_admin: bool = false

func _init(client_id: int) -> void:
	_id = client_id

func _to_string() -> String:
	if nickname.is_empty():
		return "Peer(%s)"%id
	else: return nickname

## Creates new Client-Server instance
static func create_server() -> EchonetPeer:
	var peer := EchonetPeer.new(1)
	peer.is_admin = true
	return peer

## Creates a new Client instance
static func create_client(client_id: int = 0) -> EchonetPeer:
	var peer := EchonetPeer.new(client_id)
	return peer

## Creates placeholder peer for when client info is unknown
static func placeholder() -> EchonetPeer:
	var peer := EchonetPeer.new(-1)
	peer.nickname = "???"
	return peer
