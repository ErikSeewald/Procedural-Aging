extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var ui: Panel = $UI
@onready var complexity_edit: SpinBox = $UI/MarginContainer/VBoxContainer/Complexity

@onready var meshes = [SphereMesh.new(), QuadMesh.new()]
var mesh_index = 0

var _default_segments := 64
var _default_rings := 32

@onready var prev_vsync_setting = DisplayServer.window_get_vsync_mode()

func set_instance_mesh(index: int) -> void:
	mesh_index = index % len(meshes)
	mesh_instance.mesh = meshes[mesh_index]
	mesh_instance.transform = Transform3D()
	
	complexity_edit.visible = mesh_instance.mesh is SphereMesh	

func change_triangles(factor: float) -> void:
	var mesh = mesh_instance.mesh
	if mesh is SphereMesh:
		mesh.radial_segments = max(1, _default_segments * factor)
		mesh.rings = max(1, _default_rings * factor)

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(0, shader)

func _ready() -> void:
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	ui.visible = false
	
func _exit_tree() -> void:
	DisplayServer.window_set_vsync_mode(prev_vsync_setting)
