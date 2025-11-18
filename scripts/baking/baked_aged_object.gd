extends MeshInstance3D

@export var material_to_slot: Dictionary[ShaderMaterial, int]
@export var bake_resolution: Vector2i = Vector2i(2048, 2048)

func _ready() -> void:
	for mat in material_to_slot.keys():
		AgeBaker.register(self, mat, bake_resolution, material_to_slot[mat])

## Exports the bake target textures of the material at the given slot to the
## given path. If the current material does not have these textures, nothing
## is exported.
func export_textures(path: String, slot: int) -> void:
	var mat = get_surface_override_material(slot)
	for tex_name in AgeBaker.bake_targets.keys():
		var tex: Texture2D = mat.get_shader_parameter(tex_name)
		if tex:
			var img: Image = tex.get_image()
			img.save_png(path.path_join(tex_name + ".png"))
