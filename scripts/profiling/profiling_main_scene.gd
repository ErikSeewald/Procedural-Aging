extends Node

@export var base_mat: ShaderMaterial
@export var tex_mat: ShaderMaterial

const shaders: Array = [
	preload("res://shaders/pm_aging.gdshader"),
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
	
	for shader in shaders:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		shader_materials.append(mat)
		
	# brute force for now
	shader_materials[0] = base_mat
	shader_materials[2] = tex_mat
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle"):
		ui.visible = !ui.visible
		if _cur_scene_child.has_method("toggle_ui"):
			_cur_scene_child.toggle_ui(ui.visible)

func switch_shader() -> void:
	_shader_index = (_shader_index + 1) % len(shaders)
	if _cur_scene_child.has_method("switch_to_shader"):
		_cur_scene_child.switch_to_shader(shader_materials[_shader_index])
	

func switch_scene() -> void:
	if _cur_scene_child:
		_cur_scene_child.queue_free()
	
	_scene_index = (_scene_index + 1) % len(scenes)
	_cur_scene_child = scenes[_scene_index].instantiate()
	add_child(_cur_scene_child)
	
