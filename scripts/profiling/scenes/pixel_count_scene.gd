extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D

var _cur_distance := 1.0

const profiling_length := 2.0
var _cur_profiling_length = 0.0

const profiling_ids: Array[String] = [
	"dist_0.25", "dist_1", "dist_10", "dist_100"
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)	
	_cur_distance = float(profiling_id.split("_")[-1])

func _ready() -> void:
	super()
	set_distance(_cur_distance)

func _process(delta: float) -> void:
	super(delta)
	mesh_instance.set_instance_shader_parameter("age", _cur_age)
	
	_cur_profiling_length += delta
	if _cur_profiling_length >= profiling_length:
		profiling_sequence_finished.emit()
	
func switch_to_shader(mat: ShaderMaterial) -> void:
	super(mat)
	mesh_instance.set_surface_override_material(material_slot, _cur_mat)

func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	super(mat, size)
	AgeBaker.register(mesh_instance, _cur_mat, _cur_bake_size, material_slot)
	AgeBaker.bake()

## Sets the distance of the test quad from the camera to the given float
func set_distance(distance: float) -> void:
	mesh_instance.global_position = camera.global_position - Vector3(0.0, 0.0, distance)
