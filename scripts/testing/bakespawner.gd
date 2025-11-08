extends Node3D

@export var target: MeshInstance3D
@export var n: int = 1

func _ready() -> void:
	for x in range(n):
		for z in range(n):
			if x == 0 and z == 0:
				continue
				
			var m = target.duplicate()
			m.bake_material = m.bake_material.duplicate()
			m.bake_material.set_shader_parameter("age", x*5 + z*10)
			m.bake_material.set_shader_parameter("seed", m.get_instance_id())
			m.translate(Vector3(x, 0, z))
			m.visible = true
			add_child(m)
