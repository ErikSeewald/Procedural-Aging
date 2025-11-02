extends Node

@onready var profiler: Profiler = $Profiler
@onready var ui: Panel = $UI
@onready var pause_aging_btn: CheckButton = $"UI/MarginContainer/VBoxContainer/Pause aging"

const scenes: Array = [
	preload("res://scenes/profiling/rotating_mesh.tscn"),
	preload("res://scenes/profiling/multiple_objects.tscn"),
	preload("res://scenes/profiling/pixel_count.tscn"),
	preload("res://scenes/profiling/env_and_lights.tscn")
]
var _scene_index = 0
var _cur_scene: ProfilingScene
var _cur_scene_profiling_idx := 0

var _aging_paused = false
var _ui_enabled = true
var _cur_bake_size := Vector2i(2048, 2048)

var _profiling_shaders: ProfilingShaders
var _shader_index = 0

func _ready() -> void:
	ui.visible = false
	_profiling_shaders = ProfilingShaders.new()
	set_scene(0)

func _input(event: InputEvent) -> void:
	if _ui_enabled and event.is_action_pressed("ui_toggle"):
		toggle_ui(!ui.visible)

## Toggles ui and propagates the setting down to child UIs
func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	_cur_scene.toggle_ui(ui.visible)

## Toggles pausing the aging in the child scene
func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled
	_cur_scene.pause_aging(toggled)

## Sets the currently displayed shader by index and
## propagates the setting down to child scenes
func set_shader(index: int) -> void:
	_shader_index = index % len(ProfilingShaders.shaders)
	var mat = _profiling_shaders.get_material_copy(_shader_index)
	
	if _shader_index == ProfilingShaders.baked_index:
		pause_aging_btn.button_pressed = true
		_cur_scene.bake_shader(mat, _cur_bake_size)
	else:
		_cur_scene.switch_to_shader(mat)

## Sets the resolution that will be used for the baked shader textures
## and resets the current bake (if it is active).
func set_bake_res(size: int) -> void:
	_cur_bake_size = Vector2i(size, size)
	set_shader(_shader_index)

## Sets the current profiling scene and frees the old one.
## Applies (and, if needed, resets) the profiling id index.
func set_scene(index: int) -> void:
	if _cur_scene:
		_cur_scene.queue_free()
		
	var new_index = index % len(scenes)
	if new_index != _scene_index:
		_cur_scene_profiling_idx = 0
		
	_scene_index = new_index
	_cur_scene = scenes[_scene_index].instantiate()
	_cur_scene.setup(_cur_scene.profiling_ids[_cur_scene_profiling_idx])
	add_child(_cur_scene)
	
	# Copy current parameters over
	set_shader(_shader_index)
	toggle_ui(ui.visible)
	pause_aging(_aging_paused)

func toggle_vsync(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func reset_scene() -> void:
	set_scene(_scene_index)
	
## Connects to the saved_data signal of the profiler
func on_profiler_saved() -> void:
	_cur_scene_profiling_idx += 1
	
	var ids = _cur_scene.profiling_ids
	if _cur_scene_profiling_idx >= len(ids):
		if _scene_index + 1 >= len(scenes):
			get_tree().quit()
			return
		else:
			_cur_scene_profiling_idx = 0
			_scene_index += 1
	
	reset_scene()
	profiler.warmup_and_run(ids[_cur_scene_profiling_idx])
	
## Runs the profiling suite, takes away control from the user and sets up
## the profiler.
func run_suite() -> void:
	_ui_enabled = false
	toggle_ui(false)
	toggle_vsync(false)
	reset_scene()
	get_window().size = Vector2i(1920, 1080)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	
	var profiling_id = _cur_scene.profiling_ids[0]
	profiler.warmup_and_run(profiling_id)
