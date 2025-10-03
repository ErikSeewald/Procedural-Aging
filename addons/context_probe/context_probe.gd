# Probe with a collision shape and ContextParams.
# ContextSamplers can sample the parameters of probes that they are colliding
# with.

@icon("res://addons/context_probe/probe_icon.svg")
extends Area3D
class_name ContextProbe

@export var params := ContextParams.new()

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true
