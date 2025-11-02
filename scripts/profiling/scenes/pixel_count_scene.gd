extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D

const profiling_ids: Array[String] = [
	"pixel_count_1"
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)

func _process(delta: float) -> void:
	super(delta)
	mesh_instance.set_instance_shader_parameter("age", _cur_age)
	
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
