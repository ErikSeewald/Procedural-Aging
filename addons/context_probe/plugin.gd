@tool
extends EditorPlugin

var probe_script := preload("context_probe.gd")
var probe_icon := preload("probe_icon.svg")

func _enter_tree() -> void:
	add_custom_type("ContextProbe", "Area3D", probe_script, probe_icon)

func _exit_tree() -> void:
	remove_custom_type("ContextProbe")
