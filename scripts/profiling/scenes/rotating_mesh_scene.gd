extends ProfilingScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var complexity_edit: SpinBox = $UI/MarginContainer/VBoxContainer/Complexity

@onready var meshes = [SphereMesh.new(), QuadMesh.new()]
var _mesh_index = 0

const _default_segments := 64
const _default_rings := 32
var _complexity_factor := 1.0

const profiling_ids: Array[String] = [
	"rotating_sphere_complexity_1", "rotating_sphere_complexity_5", "rotating_sphere_complexity_10",
	"rotating_quad"
]

func get_profiling_ids() -> Array[String]:
	return profiling_ids

func _setup_existing_id(profiling_id: String) -> void:
	print("SETUP " + profiling_id)
	
	if "complexity" in profiling_id:
		_complexity_factor = int(profiling_id.split("_")[-1])
	elif profiling_id == "rotating_quad":
		_mesh_index = 1

func switch_to_shader(mat: ShaderMaterial) -> void:
	super(mat)
	mesh_instance.set_surface_override_material(material_slot, _cur_mat)
	
func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	super(mat, size)
	AgeBaker.register(mesh_instance, _cur_mat, _cur_bake_size, material_slot)
	AgeBaker.bake()
	
func _ready() -> void:
	super()
	set_instance_mesh(_mesh_index)
	set_complexity(_complexity_factor)
	
func _process(delta: float) -> void:
	super(delta)
	mesh_instance.set_instance_shader_parameter("age", _cur_age)
		
	if mesh_instance.mesh is QuadMesh:
		mesh_instance.rotate_z(delta * 0.25)
	else:
		mesh_instance.rotate_y(delta * 0.25)

## Sets the mesh of the MeshInstance3D to the mesh at the given index
## and resets its transform
func set_instance_mesh(index: int) -> void:
	_mesh_index = index % len(meshes)
	mesh_instance.mesh = meshes[_mesh_index]
	mesh_instance.transform = Transform3D()
	
	complexity_edit.visible = mesh_instance.mesh is SphereMesh	
	if _baked_mode: # Unlike the real-time shader the texture needs to be rebaked for a new mesh
		bake_shader(_cur_mat, _cur_bake_size)

## Sets the triangle complexity of the displayed mesh based on the given factor.
## Only implemented for the SphereMesh
func set_complexity(factor: float) -> void:
	var mesh = mesh_instance.mesh
	if mesh is SphereMesh:
		mesh.radial_segments = max(1, _default_segments * factor)
		mesh.rings = max(1, _default_rings * factor)
