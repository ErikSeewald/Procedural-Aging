# Probe with a collision shape and ContextParams.
# ContextSamplers can sample the parameters of probes that they are colliding
# with.

@tool
@icon("res://addons/context_probe/probe_icon.svg")
extends Area3D
class_name ContextProbe

@onready var collision_shape: CollisionShape3D = get_node_or_null(shape_name)
const shape_name := "ProbeShape"

@export var params := ContextParams.new()

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		# QoL: Creating a ContextProbe should create the collision shape as well
		if not get_node_or_null(shape_name):
			collision_shape = CollisionShape3D.new()
			collision_shape.name = shape_name
			add_child(collision_shape)
			collision_shape.owner = get_tree().edited_scene_root

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not get_node_or_null(shape_name):
		warnings.append("A ContextProbe cannot function without a CollisionShape3D named 'ProbeShape'")
		
	for node in get_children():
		if node is CollisionShape3D and node.name != shape_name:
			warnings.append("A ContextProbe will only consider the CollisionShape3D named 'ProbeShape'")
			break
	
	return warnings
