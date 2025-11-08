extends Node3D

@export var instance_count := 100
@onready var base: MeshInstance3D = $BaseInstance

var _instances: Array[MeshInstance3D] = []

func _ready() -> void:
	var root := int(sqrt(instance_count))
	for i in range(1, instance_count):
		var inst = base.duplicate(DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
		inst.position = inst.position + Vector3((i % root) * 1.5, 0.0, i / floor(root) * 1.5)
		inst.set_instance_shader_parameter("age", float(i))
		inst.set_instance_shader_parameter("seed", inst.get_instance_id())
		add_child(inst)
		_instances.append(inst)
		
