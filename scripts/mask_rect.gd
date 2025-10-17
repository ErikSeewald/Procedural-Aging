extends ColorRect

## Displays a cutout of the target object's shader mask
## the z_offset specified in the ColorRect's material.
@export var target_obj: AgingObject

func _process(_delta) -> void:
	if target_obj:
		for u in target_obj.mat.shader.get_shader_uniform_list():
			var value = target_obj.mat.get_shader_parameter(u.name)
			material.set_shader_parameter(u.name, value)
