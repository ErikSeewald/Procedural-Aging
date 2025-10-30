extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var ui: Panel = $UI
@onready var complexity_edit: SpinBox = $UI/MarginContainer/VBoxContainer/Complexity

@onready var meshes = [SphereMesh.new(), QuadMesh.new()]
var _mesh_index = 0

var _default_segments := 64
var _default_rings := 32

var _cur_age := 0.0

func _ready() -> void:
	ui.visible = false
	
func _process(delta: float) -> void:
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

## Sets the triangle complexity of the displayed mesh based on the given factor.
## Only implemented for the SphereMesh
func set_complexity(factor: float) -> void:
	var mesh = mesh_instance.mesh
	if mesh is SphereMesh:
		mesh.radial_segments = max(1, _default_segments * factor)
		mesh.rings = max(1, _default_rings * factor)

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(0, shader)
