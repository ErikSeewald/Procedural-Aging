@tool
@icon("res://addons/context_probe/icon.svg")
extends Area3D
class_name ContextProbe

@export var params := ContextParams.new()
@onready var collision_shape: CollisionShape3D = get_node_or_null("ProbeCollisionShape")
const probe_collision_layer := 9

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		if not get_node_or_null("ProbeCollisionShape"):
			collision_shape = CollisionShape3D.new()
			collision_shape.name = "ProbeCollisionShape"
			add_child(collision_shape)
			collision_shape.owner = get_tree().edited_scene_root

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true
	collision_layer = probe_collision_layer
