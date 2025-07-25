## Main [EditorPlugin] for Echonet Multiplayer Framework
@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Echonet", "global/echonet.gd")
	add_autoload_singleton("EchonetDebug", "global/scenes/echonet_debug.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("Echonet")
	remove_autoload_singleton("EchonetDebug")
