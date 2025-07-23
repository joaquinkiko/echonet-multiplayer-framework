## [EditorPlugin] for Snapnet Multiplayer Framework
@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Snapnet", "global/snapnet.gd")
	add_autoload_singleton("SnapnetDebug", "global/scenes/snapnet_debug.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("Snapnet")
	remove_autoload_singleton("SnapnetDebug")
