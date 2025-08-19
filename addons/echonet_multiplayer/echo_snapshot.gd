## Stores world state at a point in time
class_name EchoSnapshot extends RefCounted

## Tick this snapshot belongs to
var tick: int
## A collection of current world state at the time of this Snapshot
## Key: 24-bit combined [EchoNode] & [EchoScene] ID
## Value: Encoded [EchoNode] State data
var world_state: Dictionary[int, PackedByteArray]

static func new_from_state_packet(packet: StatePacket) -> EchoSnapshot:
	var output := EchoSnapshot.new()
	output.tick = packet.tick
	var position: int
	while position + 3 < packet.state_data.size():
		var scene := packet.state_data.decode_u16(position)
		var count := packet.state_data.decode_u8(position + 2)
		position += 3
		for n in count:
			var node := packet.state_data.decode_u8(position)
			var length := EchoScene.scenes[scene].echo_nodes[node].decode_state_data_length(packet.state_data.slice(position))
			output.world_state[EchoScene.scenes[scene].echo_nodes[node].get_combined_id()] = packet.state_data.slice(position, position + length + 1)
			position += length + 1
	return output

func get_state_data() -> PackedByteArray:
	var data: PackedByteArray
	var scenes: Dictionary[int, PackedInt32Array]
	for n in world_state.keys():
		if !scenes.has(EchoNode.get_scene_id_from_combined_id(n)):
			scenes[EchoNode.get_scene_id_from_combined_id(n)] = PackedInt32Array([EchoNode.get_node_id_from_combined_id(n)])
		elif !scenes[EchoNode.get_scene_id_from_combined_id(n)].has(EchoNode.get_node_id_from_combined_id(n)):
			scenes[EchoNode.get_scene_id_from_combined_id(n)].append(EchoNode.get_node_id_from_combined_id(n))
	for n in scenes:
		data.resize(data.size() + 3)
		data.encode_u16(data.size() - 3, n)
		data.encode_u8(data.size() - 1, scenes[n].size())
		for i in scenes[n]:
			data.append_array(EchoScene.scenes[n].echo_nodes[i].get_encoded_state())
	return data

static func layer_snapshots(base: EchoSnapshot, layer: EchoSnapshot) -> EchoSnapshot:
	base.tick = layer.tick
	for n in layer.world_state.keys():
		base.world_state[n] = layer.world_state[n]
	return base

static func delta_snapshot(base: EchoSnapshot, layer: EchoSnapshot) -> EchoSnapshot:
	var delta := EchoSnapshot.new()
	delta.tick = layer.tick
	for n in layer.world_state.keys():
		if base.world_state.get(n, null) != layer.world_state[n]:
			delta.world_state[n] = layer.world_state[n]
	return delta
