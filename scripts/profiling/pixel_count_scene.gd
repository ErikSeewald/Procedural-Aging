extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D
@onready var ui: Panel = $UI

const material_slot := 0
var _cur_age := 0.0
var _aging_paused := false

func _ready() -> void:
	ui.visible = false

func _process(delta: float) -> void:
	if not _aging_paused:
		_cur_age += delta
		mesh_instance.set_instance_shader_parameter("age", _cur_age)

func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(material_slot, shader)

## Sets the distance of the test quad from the camera to the given float
func set_distance(distance: float) -> void:
	mesh_instance.global_position = camera.global_position - Vector3(0.0, 0.0, distance)
	
func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	mat.set_shader_parameter("age", _cur_age)
	AgeBaker.register(mesh_instance, mat, size, material_slot)
	AgeBaker.bake()
