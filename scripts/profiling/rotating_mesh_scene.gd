extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var ui: Panel = $UI

@onready var meshes = [SphereMesh.new(), QuadMesh.new()]
var mesh_index = 0

var _default_segments := 64
var _default_rings := 32
var _default_subdiv := 0

@onready var prev_vsync_setting = DisplayServer.window_get_vsync_mode()

func switch_instance_mesh() -> void:
	mesh_index = (mesh_index + 1) % len(meshes)
	mesh_instance.mesh = meshes[mesh_index]
	mesh_instance.transform = Transform3D()
	
func change_triangles(factor: float) -> void:
	var mesh = mesh_instance.mesh
	if mesh is SphereMesh:
		mesh.radial_segments = max(1, _default_segments * factor)
		mesh.rings = max(1, _default_rings * factor)
	elif mesh is QuadMesh:
		mesh.subdivide_depth = max(0, _default_subdiv * factor)
		mesh.subdivide_width = max(0, _default_subdiv * factor)

func toggle_ui(toggled: bool) -> void:
	ui.visible = toggled
	
func switch_to_shader(shader: ShaderMaterial) -> void:
	mesh_instance.set_surface_override_material(0, shader)

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	ui.visible = false
	
func _exit_tree() -> void:
	DisplayServer.window_set_vsync_mode(prev_vsync_setting)
