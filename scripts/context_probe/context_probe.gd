extends Area3D
class_name ContextProbe

@export var params: ContextParams
@onready var _collision_sphere: SphereShape3D = $CollisionSphere.shape
const probe_collision_layer := 6

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true
	collision_layer = probe_collision_layer

func get_radius() -> float:
	return _collision_sphere.radius
