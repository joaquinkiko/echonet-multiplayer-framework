## [EditorPlugin] for Snapnet Multiplayer Framework
@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Snapnet", "global/snapnet.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("Snapnet")
