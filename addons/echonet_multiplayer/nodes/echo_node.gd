## Node to be syncronized over the network
class_name EchoNode extends Node

## Unique ID of this node relative to it's [member parent_echo_scene] ID
var id: int
## Parent [EchoScene]
var parent_echo_scene: EchoScene

## List of valid [EchoFunc] sorted by method call name
@export var echo_funcs: Dictionary[StringName, EchoFunc]

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
			return possible_parent.get_meta("echoscene", EchoScene.get_root())
		possible_parent = possible_parent.get_parent()
	return EchoScene.get_root()

## Calls a method from [echo_funcs] and broadcasts it remotely
func remote_call(method: StringName, args: Array) -> Variant:
	if !echo_funcs.has(method):
		push_warning("Locally called method '%s' not found in %s"%[method, self])
		return null
	Echonet.transport.remote_call(self, 
		method, 
		echo_funcs[method].encode_args(args), 
		echo_funcs[method].reliable)
	return echo_funcs[method].remote_call(args, self)

## Called when receiving a remote method call
func receive_remote_call(method: StringName, args_data: PackedByteArray, caller: EchonetPeer) -> void:
	if !echo_funcs.has(method):
		push_warning("Remotely called method '%s' not found in %s"%[method, self])
		return
	echo_funcs[method].receive_remote_call(args_data, self, caller)

func get_echo_func_id(method: StringName) -> int:
	var methods := PackedStringArray(echo_funcs.keys().duplicate())
	methods.sort()
	for n in methods.size():
		if methods[n] == method: return n
	return -1

func find_echo_func_by_id(id: int) -> StringName:
	var methods := PackedStringArray(echo_funcs.keys().duplicate())
	methods.sort()
	if id < methods.size() && id >= 0:
		return methods[id]
	else: return &""
