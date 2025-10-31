extends ColorRect

@export var target_obj: MeshInstance3D

func _process(_delta) -> void:
	if target_obj:
		var mat = target_obj.get_active_material(0)
		for u in mat.shader.get_shader_uniform_list():
			var value = mat.get_shader_parameter(u.name)
			material.set_shader_parameter(u.name, value)
