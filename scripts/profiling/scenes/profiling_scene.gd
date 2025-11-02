@abstract
extends Node3D
class_name ProfilingScene

## Called when a profiling sequence defined by a profiling id has finished.
## Can be ignored if there is currently no profiling going on.
@warning_ignore("unused_signal")
signal profiling_sequence_finished

## Used to throw an error if _ready() is called without calling setup().
## (i.e. if the node was added to a tree before setup())
@warning_ignore("unused_private_class_variable")
var _is_setup: bool = false

## All ProfilingScenes have a UI panel. If there is no need for an interface,
## the empty panel should still exist.
@warning_ignore("unused_private_class_variable")
@onready var _ui: Panel = $UI

## All ProfilingScenes have a global age that is shared between the different
## geometry instances.
var _cur_age := 0.0
var _aging_factor := 1.0
var _aging_paused = false

## All ProfilingScenes handle material switching and baking in some way.
## Some do not need to keep track of the variables related to baking, but
## enough do to warrent keeping them in the base class.
const material_slot := 0
var _cur_mat: ShaderMaterial
var _baked_mode = false
var _cur_bake_size: Vector2i

## Sets the scene up for profiling corresponding to the given id. 
## Can only be called right after creating the node. 
## New setups should use newly instantiated scenes.
## Has to be called BEFORE _process runs for the first time in this node.
func setup(profiling_id: String) -> void:
	if profiling_id not in get_profiling_ids():
		push_error(profiling_id + " does not exist!")
		return
	_setup_existing_id(profiling_id)
	_is_setup = true

## Implements the scene setup for the given profiling id without handling
## the case of the id not existing.
## Also assumes that _is_setup is handled by the caller.
@abstract
func _setup_existing_id(profiling_id: String) -> void

## Returns the IDs of all possible profiling setup within this scene.
@abstract
func get_profiling_ids() -> Array[String]

## Toggles the visibility of the scene UI panel.
func toggle_ui(toggled: bool) -> void:
	_ui.visible = toggled
	
## Pauses/unpauses the aging updating process.
func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled

## Sets the factor by which delta time is scaled in the aging update process.
func set_aging_factor(factor: float) -> void:
	_aging_factor = factor

## Switches to the given shader material. Intended to be used with super()
## before the scene specific implementation.
func switch_to_shader(mat: ShaderMaterial) -> void:
	_baked_mode = false
	_cur_mat = mat
	
## Switches to the baked version of pma. Intended to be used with super()
## before the scene specific implementation.
func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	_baked_mode = true
	_cur_bake_size = size
	_cur_mat = mat
	_cur_mat.set_shader_parameter("age", _cur_age)

## Intended to be used with super() before the scene specific implementation.
func _ready() -> void:
	if not _is_setup:
		push_error("Scene was not setup!")
		return
		
	_ui.visible = false

## Intended to be used with super() before the scene specific implementation.
func _process(delta: float) -> void:
	if not _aging_paused:
		_cur_age += delta * _aging_factor
