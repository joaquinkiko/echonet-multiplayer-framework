## Handles sending RPCs over the network
class_name RPCPacket extends EchonetPacket

var echo_node: EchoNode
var method: StringName
var args_data: PackedByteArray
var caller: EchonetPeer

func _init(_echo_node: EchoNode = null, _method := &"", _args_data := PackedByteArray([]), _caller: EchonetPeer = null) -> void:
	type = PacketType.RPC
	echo_node = _echo_node
	method = _method
	args_data = _args_data
	caller = _caller


## Transforms generic [EchonetPacket] for use after being received from remote peer
static func new_remote(packet: EchonetPacket) -> RPCPacket:
	var output := RPCPacket.new()
	output.data = packet.data
	output.sender = packet.sender
	output.decode()
	return output

func encode() -> PackedByteArray:
	super.encode()
	data.resize(6)
	data.encode_u16(1, echo_node.parent_echo_scene.id)
	data.encode_u8(3, echo_node.id)
	data.encode_u8(4, echo_node.get_echo_func_id(method))
	if caller != null: data.encode_u8(5, caller.id)
	data.append_array(args_data)
	return data

func decode() -> void:
	super.decode()
	var echo_scene := EchoScene.scenes.get(data.decode_u16(1), null)
	if echo_scene != null:
		echo_node = echo_scene.echo_nodes.get(data.decode_u8(3), null)
		if echo_node != null: method = echo_node.find_echo_func_by_id(data.decode_u8(4))
	Echonet.transport.client_peers.get(data.decode_u8(5), EchonetPeer.placeholder())
	args_data = data.slice(6)

func attempt_to_decode_node() -> void:
	var echo_scene := EchoScene.scenes.get(data.decode_u16(1), null)
	if echo_scene != null:
		echo_node = echo_scene.echo_nodes.get(data.decode_u8(3), null)
		if echo_node != null: method = echo_node.find_echo_func_by_id(data.decode_u8(4))
