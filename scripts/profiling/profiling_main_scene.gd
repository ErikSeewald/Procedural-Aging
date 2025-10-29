extends Node

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
	preload("res://shaders/instanced_pm_aging.gdshader"),
	preload("res://shaders/debug/baseline.gdshader"),
	preload("res://shaders/debug/baseline_textured.gdshader")
]
var shader_materials: Array
var _shader_index = 0

const scenes: Array = [
	preload("res://scenes/profiling/rotating_mesh.tscn"),
	preload("res://scenes/profiling/multiple_objects.tscn")
]
var _scene_index = 0
var _cur_scene_child: Node

@onready var ui: Panel = $UI

func _ready() -> void:
	ui.visible = false
	_cur_scene_child = scenes[0].instantiate()
	add_child(_cur_scene_child)
	
	_initialize_shaders()

func _initialize_shaders() -> void:
	for shader in shaders:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		shader_materials.append(mat)
	
	var metallic_base := TextureHelper.get_unit_texture(Color(0.6, 0.6, 0.6));
	var metallic_paint := TextureHelper.get_unit_texture(Color(0.4, 0.4, 0.4));
	
	shader_materials[0].set_shader_parameter("albedo_base", base_textures[0])
	shader_materials[0].set_shader_parameter("metallic_base", metallic_base)
	shader_materials[0].set_shader_parameter("roughness_base", base_textures[1])
	shader_materials[0].set_shader_parameter("normal_base", base_textures[2])
	
	shader_materials[0].set_shader_parameter("albedo_paint", paint_textures[0])
	shader_materials[0].set_shader_parameter("metallic_paint", metallic_paint)
	shader_materials[0].set_shader_parameter("roughness_paint", paint_textures[1])
	shader_materials[0].set_shader_parameter("normal_paint", paint_textures[2])
	
	shader_materials[2].set_shader_parameter("albedo", paint_textures[0])
	shader_materials[2].set_shader_parameter("metallic", metallic_paint)
	shader_materials[2].set_shader_parameter("roughness", paint_textures[1])
	shader_materials[2].set_shader_parameter("normal", paint_textures[2])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle"):
		toggle_ui(!ui.visible)

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	if _cur_scene_child.has_method("toggle_ui"):
		_cur_scene_child.toggle_ui(ui.visible)

func set_scene(index: int) -> void:
	if _cur_scene_child:
		_cur_scene_child.queue_free()
	
	_scene_index = index % len(scenes)
	_cur_scene_child = scenes[_scene_index].instantiate()
	add_child(_cur_scene_child)
	
	# Copy current parameters over
	set_shader(_shader_index)
	toggle_ui(ui.visible)
	
func set_shader(index: int) -> void:
	_shader_index = index % len(shaders)
	if _cur_scene_child.has_method("switch_to_shader"):
		_cur_scene_child.switch_to_shader(shader_materials[_shader_index])
		
func reset_scene() -> void:
	set_scene(_scene_index)
