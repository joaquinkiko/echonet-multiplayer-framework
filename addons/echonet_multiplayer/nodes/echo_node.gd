class_name EchoNode extends Node

var parent_id: int
var parent_node: Node
var id: int

func _enter_tree() -> void:
	parent_node = _find_parent_spawned_object()
	if parent_node != null: 
		parent_id = parent_node.get_meta("id", -1)
		id = get_meta("subidcounter", 0) + 1
		parent_node.set_meta("subidcounter", id)
		#print("New EchoNode (%s)(%s)(%s)"%[parent_node, parent_id, id])
	else: push_warning("EchoNode should be spawned in!")

## Returns parent spawned object
func _find_parent_spawned_object() -> Node:
	var possible_parent: Node = self
	while possible_parent != null:
		if possible_parent.has_meta("id"):
			return possible_parent
		possible_parent = possible_parent.get_parent()
	return null
