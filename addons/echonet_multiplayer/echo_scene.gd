class_name EchoScene extends RefCounted

const MAX_SCENES := 65535 # Max u16

static var scenes: Dictionary[int, EchoScene]
static var echo_id_counter: int = 1

var node: Node
var id: int
var owner: EchonetPeer
var echo_nodes: Dictionary[int, EchoNode]

static func _static_init() -> void:
	if !scenes.has(0): scenes[0] = EchoScene.new(null, 0, null)

## Get next available scene id
static func get_available_scene_id() -> int:
	var output := 0
	while scenes.keys().has(output):
		output +=1
	return output

## Remove all current [member scenes]
static func clear_scenes() -> void:
	for echo_scene in scenes.values(): if echo_scene.node != null: echo_scene.node.queue_free()
	scenes.clear()

## Add an [EchoScene] to [member scenes]
static func add_scene(scene: EchoScene) -> void:
	scenes[scene.id] = scene

## Remove and [EchoScene] from [member scenes]
static func remove_scene(scene_id: int) -> void:
	if scenes[scene_id].node != null: scenes[scene_id].node.queue_free()
	scenes.erase(scene_id)

## Gets root [EchoScene]
static func get_root() -> EchoScene:
	if !scenes.has(0): scenes[0] = EchoScene.new(null, 0, null)
	return scenes[0]

func _init(_node: Node = null, _id: int = -1, _owner: EchonetPeer = null) -> void:
	node = _node
	id = _id
	owner = _owner
	if node != null:
		node.set_meta("echoscene", self)

func get_available_echo_node_id() -> int:
	var output: int = echo_id_counter
	var has_looped: bool = false
	while echo_nodes.has(output):
		output += 1
		if output > MAX_SCENES: 
			if has_looped:
				push_error("Overflow on EchoScene IDs!!!")
				break
			output = 1
			has_looped = true
	echo_id_counter = output + 1
	if echo_id_counter > MAX_SCENES: echo_id_counter = 1
	return output

func is_mine() -> bool:
	if owner == null: return false
	else: return owner.is_self
