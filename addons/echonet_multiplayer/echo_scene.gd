class_name EchoScene extends RefCounted

var node: Node
var id: int
var owner: EchonetPeer
var echo_nodes: Dictionary[int, EchoNode]

func _init(_node: Node = null, _id: int = -1, _owner: EchonetPeer = null) -> void:
	node = _node
	id = _id
	owner = _owner
	if node != null:
		node.set_meta("echoscene", self)

func get_available_echo_node_id() -> int:
	var output: int = 0
	while echo_nodes.has(output):
		output += 1
	return output

func is_mine() -> bool:
	if owner == null: return false
	else: return owner.is_self
