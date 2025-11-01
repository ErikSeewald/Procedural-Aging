extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var ui: Panel = $UI
@onready var complexity_edit: SpinBox = $UI/MarginContainer/VBoxContainer/Complexity

@onready var meshes = [SphereMesh.new(), QuadMesh.new()]
var _mesh_index = 0

const material_slot := 0
const _default_segments := 64
const _default_rings := 32

var _cur_mat: ShaderMaterial
var _baked_mode = false
var _cur_bake_size: Vector2i

var _cur_age := 0.0
var _aging_paused = false

func _ready() -> void:
	ui.visible = false
	
func _process(delta: float) -> void:
	if not _aging_paused:
		_cur_age += delta
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

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled

func pause_aging(toggled: bool) -> void:
	_aging_paused = toggled

func switch_to_shader(mat: ShaderMaterial) -> void:
	_baked_mode = false
	_cur_mat = mat
	mesh_instance.set_surface_override_material(material_slot, mat)
	
func bake_shader(mat: ShaderMaterial, size: Vector2i) -> void:
	_baked_mode = true
	_cur_mat = mat
	_cur_bake_size = size
	mat.set_shader_parameter("age", _cur_age)
	AgeBaker.register(mesh_instance, mat, size, material_slot)
	AgeBaker.bake()
