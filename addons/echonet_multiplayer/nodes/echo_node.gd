class_name EchoNode extends Node

var id: int
var parent_echo_scene: EchoScene

func _enter_tree() -> void:
	parent_echo_scene = _find_parent_echo_scene()
	assert(parent_echo_scene != null, "EchoNode entered tree with no parent EchoScene!")
	id = parent_echo_scene.get_available_echo_node_id()
	parent_echo_scene.echo_nodes[id] = self

func _exit_tree() -> void:
	if parent_echo_scene != null && parent_echo_scene.echo_nodes.has(id):
		parent_echo_scene.echo_nodes.erase(id)

## Returns parent spawned object
func _find_parent_echo_scene() -> EchoScene:
	var possible_parent: Node = self
	while possible_parent != null:
		if possible_parent.has_meta("echoscene"):
			return possible_parent.get_meta("echoscene", EchoScene.scenes[0])
		possible_parent = possible_parent.get_parent()
	return EchoScene.scenes[0]
