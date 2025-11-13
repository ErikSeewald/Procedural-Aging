extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D

var _cur_size := 1.0

const profiling_length := 5.0
var _cur_profiling_length = 0.0

const profiling_ids: Array[String] = [
	 "scale_1", "scale_0.5", "scale_0.25", "scale_0.05",
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)	
	_cur_size = float(profiling_id.split("_")[-1])

func _ready() -> void:
	super()
	set_size(_cur_size)

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

## Sets the size of the test quad
func set_size(size: float) -> void:
	mesh_instance.scale = Vector3(size, size, size)
