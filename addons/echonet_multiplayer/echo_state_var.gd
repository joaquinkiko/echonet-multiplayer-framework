## An [EchoVar] with extra features for state syncronization
class_name EchoStateVar extends EchoVar

@export var allowed_discrepency: float
@export_range(0.1, 1.0, .05) var interpolate_strength: float = 0.5
@export var client_prediction_allowence: float
var _original_allowed_discrepency: float

func _init() -> void:
	_original_allowed_discrepency = allowed_discrepency

func set_var(source: Node, value: Variant) -> void:
	if client_prediction_allowence != 0:
		var tick_latency: int = Echonet.transport.get_server_latency() / Echonet.transport.msec_per_tick
		allowed_discrepency = _original_allowed_discrepency + client_prediction_allowence * tick_latency
	if source.parent_echo_scene.owner.is_self:
		var source_value: Variant = get_var(source)
		match typeof(source_value):
			TYPE_INT:
				if abs(source_value - value) <= allowed_discrepency:
					return
			TYPE_FLOAT:
				if abs(source_value - value) <= allowed_discrepency:
					return
			TYPE_VECTOR2:
				if abs(source_value.x - value.x) <= allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= allowed_discrepency:
					return
			TYPE_VECTOR3:
				if abs(source_value.x - value.x) <= allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= allowed_discrepency:
					return
				elif abs(source_value.z - value.z) <= allowed_discrepency:
					return
			TYPE_VECTOR2I:
				if abs(source_value.x - value.x) <= allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= allowed_discrepency:
					return
			TYPE_VECTOR3I:
				if abs(source_value.x - value.x) <= allowed_discrepency:
					return
				elif abs(source_value.y - value.y) <= allowed_discrepency:
					return
				elif abs(source_value.z - value.z) <= allowed_discrepency:
					return
	if interpolate_strength != 1:
		value = lerp(get_var(source), value, interpolate_strength)
	super.set_var(source, value)
