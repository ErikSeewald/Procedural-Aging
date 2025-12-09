extends Node

@onready var profiler: Profiler = $Profiler
@onready var ui: Panel = $UI
@onready var pause_aging_btn: CheckButton = $"UI/MarginContainer/VBoxContainer/Pause aging"
@onready var scene_picker: OptionButton = $"UI/MarginContainer/VBoxContainer/Select scene"
@onready var sub_menu: SubMenu = $SubMenu

const scenes: Array = [
	preload("res://scenes/profiling/rotating_mesh.tscn"),
	preload("res://scenes/profiling/multiple_objects.tscn"),
	preload("res://scenes/profiling/pixel_count.tscn"),
	preload("res://scenes/profiling/lights.tscn"),
	preload("res://scenes/profiling/parameters.tscn"),
]
var _scene_index := 0
var _cur_scene: ProfilingScene
var _cur_scene_profiling_idx := 0

var _aging_paused := false
var _aging_factor := 3.0
var _cur_bake_size := Vector2i(2048, 2048)

var _profiling_shaders: ProfilingShaders
var _shader_index := 0

var _currently_profiling := false

func _ready() -> void:
	ui.visible = false
	_profiling_shaders = ProfilingShaders.new()
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)
	set_scene(0)

func _on_sub_menu_visibility() -> void:
	toggle_ui(sub_menu.visible)

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
	_cur_scene.profiling_sequence_finished.connect(on_profiling_sequence_finished)
	add_child(_cur_scene)
	
	# Copy current parameters over
	set_shader(_shader_index)
	toggle_ui(ui.visible)
	pause_aging(_aging_paused)
	_cur_scene.set_aging_factor(_aging_factor)

func toggle_vsync(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func reset_scene() -> void:
	set_scene(_scene_index)

## Runs the profiling suite, takes away control from the user, and sets up
## the profiler.
func run_suite() -> void:
	_currently_profiling = true
	sub_menu.set_input_enabled(false)
	sub_menu.visible = false
	toggle_ui(false)
	toggle_vsync(false)
	get_window().size = Vector2i(1920, 1080)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	_aging_factor = 10.0
	
	reset_scene()
	var profiling_id = _cur_scene.profiling_ids[0]
	profiler.warmup_and_run(profiling_id)

func on_profiling_sequence_finished() -> void:
	if not _currently_profiling:
		return
	
	var ids = _cur_scene.get_profiling_ids()
	_cur_scene_profiling_idx += 1
	if _cur_scene_profiling_idx >= len(ids):
		_cur_scene_profiling_idx = 0
		if _scene_index + 1 >= len(scenes):
			finish_profiling()
			return
		else:
			_scene_index += 1
	
	reset_scene()
	profiler.save_and_reset()
	ids = _cur_scene.get_profiling_ids()
	profiler.warmup_and_run(ids[_cur_scene_profiling_idx])

func finish_profiling() -> void:
	profiler.save_and_reset()
	_currently_profiling = false
	sub_menu.set_input_enabled(true)
	toggle_vsync(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	_aging_factor = 1.0
	set_scene(scene_picker.selected)
