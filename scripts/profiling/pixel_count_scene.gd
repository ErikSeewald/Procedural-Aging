extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D
@onready var ui: Panel = $UI

var _cur_age := 0.0

func _ready() -> void:
	ui.visible = false

func _process(delta: float) -> void:
	_cur_age += delta
	mesh_instance.set_instance_shader_parameter("age", _cur_age)

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(0, shader)

## Sets the distance of the test quad from the camera to the given float
func set_distance(distance: float) -> void:
	mesh_instance.global_position = camera.global_position - Vector3(0.0, 0.0, distance)
