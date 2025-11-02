extends Resource
class_name ProfilingShaders

const base_textures = [
	preload("res://assets/single_textures/rusty_metal_sheet_2k.blend/textures/rusty_metal_sheet_diff_2k.jpg"),
	preload("res://assets/single_textures/rusty_metal_sheet_2k.blend/textures/rusty_metal_sheet_rough_2k.png"),
	preload("res://assets/single_textures/rusty_metal_sheet_2k.blend/textures/rusty_metal_sheet_nor_gl_2k.png")
]

const paint_textures = [
	preload("res://assets/single_textures/green_metal_rust_2k.blend/textures/green_metal_rust_diff_2k.jpg"),
	preload("res://assets/single_textures/green_metal_rust_2k.blend/textures/green_metal_rust_rough_2k.jpg"),
	preload("res://assets/single_textures/green_metal_rust_2k.blend/textures/green_metal_rust_nor_gl_2k.png")
]

const shaders: Array = [
	preload("res://shaders/instanced_pma.gdshader"),
	preload("res://shaders/debug/baseline.gdshader"),
	preload("res://shaders/baking/baked_pma.gdshader")
]
var _shader_materials: Array
const baked_index := 2

func _init() -> void:
	for shader in shaders:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		_shader_materials.append(mat)
	
	var metallic_base := TextureHelper.get_unit_texture(Color(0.6, 0.6, 0.6));
	var metallic_paint := TextureHelper.get_unit_texture(Color(0.4, 0.4, 0.4));
	
	var pma = _shader_materials[0]
	pma.set_shader_parameter("albedo_base", base_textures[0])
	pma.set_shader_parameter("metallic_base", metallic_base)
	pma.set_shader_parameter("roughness_base", base_textures[1])
	pma.set_shader_parameter("normal_base", base_textures[2])
	
	pma.set_shader_parameter("albedo_paint", paint_textures[0])
	pma.set_shader_parameter("metallic_paint", metallic_paint)
	pma.set_shader_parameter("roughness_paint", paint_textures[1])
	pma.set_shader_parameter("normal_paint", paint_textures[2])
	
	var bake_mat = _shader_materials[baked_index]
	for u in pma.shader.get_shader_uniform_list():
		var value = pma.get_shader_parameter(u.name)
		bake_mat.set_shader_parameter(u.name, value)
		
func get_material_copy(index: int) -> ShaderMaterial:
	return _shader_materials[index].duplicate()
