class_name EchoNode extends Node

var parent_id: int
var parent_node: Node
var id: int
var parent_echo_scene: EchoScene

func _enter_tree() -> void:
	parent_echo_scene = _find_parent_echo_scene()
	if parent_echo_scene != null:
		parent_id = parent_echo_scene.id
		parent_node = parent_echo_scene.node
		id = parent_echo_scene.get_available_echo_node_id()
		parent_echo_scene.echo_nodes[id] = self
		print("New EchoNode (%s)(%s)(%s)"%[parent_node, parent_id, id])
	else: push_warning("EchoNode should have a parent EchoScene!")

func _exit_tree() -> void:
	if parent_echo_scene != null && parent_echo_scene.echo_nodes.has(id):
		parent_echo_scene.echo_nodes.erase(id)

## Returns parent spawned object
func _find_parent_echo_scene() -> EchoScene:
	var possible_parent: Node = self
	while possible_parent != null:
		if possible_parent.has_meta("echoscene"):
			return possible_parent.get_meta("echoscene", null)
		possible_parent = possible_parent.get_parent()
	return null
