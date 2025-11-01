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
	preload("res://shaders/instanced_pma.gdshader"),
	preload("res://shaders/debug/baseline.gdshader"),
	preload("res://shaders/baking/baked.gdshader")
]
var _shader_materials: Array
var _shader_index = 0

const bake_shader = preload("res://shaders/baking/baked_pma.gdshader")
var _bake_mat: ShaderMaterial

const scenes: Array = [
	preload("res://scenes/profiling/rotating_mesh.tscn"),
	preload("res://scenes/profiling/multiple_objects.tscn"),
	preload("res://scenes/profiling/pixel_count.tscn"),
	preload("res://scenes/profiling/env_and_lights.tscn")
]
var _scene_index = 0
var _cur_scene_child: Node

@onready var ui: Panel = $UI
@onready var pause_aging_btn: CheckButton = $"UI/MarginContainer/VBoxContainer/Pause aging"
var _cur_bake_size := Vector2i(2048, 2048)

func _ready() -> void:
	ui.visible = false
	_initialize_shaders()
	set_scene(0)
	
func _initialize_shaders() -> void:
	for shader in shaders:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		_shader_materials.append(mat)
	
	var metallic_base := TextureHelper.get_unit_texture(Color(0.6, 0.6, 0.6));
	var metallic_paint := TextureHelper.get_unit_texture(Color(0.4, 0.4, 0.4));
	
	_shader_materials[0].set_shader_parameter("albedo_base", base_textures[0])
	_shader_materials[0].set_shader_parameter("metallic_base", metallic_base)
	_shader_materials[0].set_shader_parameter("roughness_base", base_textures[1])
	_shader_materials[0].set_shader_parameter("normal_base", base_textures[2])
	
	_shader_materials[0].set_shader_parameter("albedo_paint", paint_textures[0])
	_shader_materials[0].set_shader_parameter("metallic_paint", metallic_paint)
	_shader_materials[0].set_shader_parameter("roughness_paint", paint_textures[1])
	_shader_materials[0].set_shader_parameter("normal_paint", paint_textures[2])
	
	_bake_mat = ShaderMaterial.new()
	_bake_mat.shader = bake_shader
	for u in _shader_materials[0].shader.get_shader_uniform_list():
		var value = _shader_materials[0].get_shader_parameter(u.name)
		_bake_mat.set_shader_parameter(u.name, value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle"):
		toggle_ui(!ui.visible)

## Toggles ui and propagates the setting down to child UIs
func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	if _cur_scene_child.has_method("toggle_ui"):
		_cur_scene_child.toggle_ui(ui.visible)

## Toggles pausing the aging in the child scene
func pause_aging(toggled: bool) -> void:
	if _cur_scene_child.has_method("pause_aging"):
		_cur_scene_child.pause_aging(toggled)

## Sets the currently displayed shader by index and
## propagates the setting down to child scenes
func set_shader(index: int) -> void:
	_shader_index = index % len(shaders)
	if _shader_index == 2:
		pause_aging_btn.button_pressed = true
		if _cur_scene_child.has_method("bake_shader"):
			_cur_scene_child.bake_shader(_bake_mat.duplicate(), _cur_bake_size)
	else:
		if _cur_scene_child.has_method("switch_to_shader"):
			_cur_scene_child.switch_to_shader(_shader_materials[_shader_index])

## Sets the resolution that will be used for the baked shader textures
## and resets the current bake (if it is active).
func set_bake_res(size: int) -> void:
	_cur_bake_size = Vector2i(size, size)
	set_shader(_shader_index)

## Sets the current profiling scene and frees the old one
func set_scene(index: int) -> void:
	if _cur_scene_child:
		_cur_scene_child.queue_free()
	
	_scene_index = index % len(scenes)
	_cur_scene_child = scenes[_scene_index].instantiate()
	add_child(_cur_scene_child)
	
	# Copy current parameters over
	set_shader(_shader_index)
	toggle_ui(ui.visible)

func reset_scene() -> void:
	set_scene(_scene_index)
