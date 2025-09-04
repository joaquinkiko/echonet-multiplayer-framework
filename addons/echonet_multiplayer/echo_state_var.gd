## An [EchoVar] with extra features for state syncronization
class_name EchoStateVar extends EchoVar

@export var allowed_discrepency: float
@export_range(0.1, 1.0, .05) var interpolate_strength: float = 0.5
var _adjusted_allowed_discrepency: float

func set_var(source: Node, value: Variant) -> void:
	if allowed_discrepency != 0:
		var tick_latency: int = Echonet.transport.get_server_latency() / Echonet.transport.msec_per_tick
		_adjusted_allowed_discrepency = allowed_discrepency + allowed_discrepency * tick_latency
	if source.parent_echo_scene.owner.is_self:
		var source_value: Variant = get_var(source)
		match typeof(source_value):
			TYPE_INT:
				if abs(source_value - value) <= _adjusted_allowed_discrepency:
					return
			TYPE_FLOAT:
				if abs(source_value - value) <= _adjusted_allowed_discrepency:
					return
			TYPE_VECTOR2:
				if abs(source_value.x - value.x) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= _adjusted_allowed_discrepency:
					return
			TYPE_VECTOR3:
				if abs(source_value.x - value.x) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.z - value.z) <= _adjusted_allowed_discrepency:
					return
			TYPE_VECTOR2I:
				if abs(source_value.x - value.x) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= _adjusted_allowed_discrepency:
					return
			TYPE_VECTOR3I:
				if abs(source_value.x - value.x) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= _adjusted_allowed_discrepency:
					return
				elif abs(source_value.z - value.z) <= _adjusted_allowed_discrepency:
					return
	if interpolate_strength != 1:
		for n in source.state_vars.size():
			if source.state_vars[n] == self:
				source.set_meta("goal%s"%n, value)
		return
	super.set_var(source, value)

func interpolate(source: Node) -> void:
	var goal_value: Variant = null
	for n in source.state_vars.size():
			if source.state_vars[n] == self && source.has_meta("goal%s"%n):
				goal_value = source.get_meta("goal%s"%n)
	if goal_value == null: return
	source.get_node(NodePath(path)).set_indexed(NodePath(NodePath(path).get_concatenated_subnames()).get_as_property_path(), lerp(get_var(source), goal_value, interpolate_strength))
