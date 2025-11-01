extends Node3D

@export var target: MeshInstance3D

func _ready() -> void:
	var s = 0
	for x in range(s):
		for z in range(s):
			var m = target.duplicate()
			m.bake_material = m.bake_material.duplicate()
			m.bake_material.set_shader_parameter("age", x*5 + z*10)
			m.bake_material.set_shader_parameter("seed", m.get_instance_id())
			m.translate(Vector3(x, 0, z))
			m.visible = true
			add_child(m)
