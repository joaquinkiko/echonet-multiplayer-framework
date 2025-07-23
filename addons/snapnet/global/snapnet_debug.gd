## Optional global class for monitoring and debugging Snapnet Multiplayer
extends Node

@onready var statistics_label: RichTextLabel = $StatisticsLabel

var statistics := PackedInt32Array([0,0,0,0,0])

## Next msec to update monitor process
var _next_monitor_update_msec := 0

func _ready() -> void: pass

func _process(delta: float) -> void:
	if Time.get_ticks_msec() >= _next_monitor_update_msec:
		var data := Snapnet.transport.gather_statistics()
		for n in 5: statistics[n] = data[n]
		statistics_label.text = """
		Data in/out:\t\t\t%s/s\t|\t%s/s
		Packets in/out:\t\t%s/s\t\t|\t%s/s
		Server RTT:\t\t\t%smsec
		"""%[
			String.humanize_size(data[0]), String.humanize_size(data[1]),
			data[2], data[3], data[4]
		]
		_next_monitor_update_msec = Time.get_ticks_msec() + 1000
