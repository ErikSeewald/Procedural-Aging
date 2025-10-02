# Autoload for mesh related helper functions like managing debug wireframe meshes.
extends Node

# MATERIALS
var wireframe_mat: StandardMaterial3D
var transparency_mat: StandardMaterial3D

# SCENES
@onready var sphere_wireframe_scene = preload("res://assets//wireframes//sphere_curve.blend").instantiate()
@onready var box_wireframe_scene = preload("res://assets//wireframes//box_wireframe.blend").instantiate()
@onready var cylinder_wireframe_scene = preload("res://assets//wireframes//cylinder_wireframe.blend").instantiate()

# MESH INSTANCES
var sphere_wireframe_inst: MeshInstance3D
var box_wireframe_inst: MeshInstance3D
var cylinder_wireframe_inst: MeshInstance3D

func _ready() -> void:
	wireframe_mat = StandardMaterial3D.new()
	wireframe_mat.albedo_color = Color(0, 1, 0.5, 1)
	wireframe_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wireframe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	transparency_mat = StandardMaterial3D.new()
	transparency_mat.albedo_color = Color(0, 1, 0.5, 0.02)
	transparency_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	transparency_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transparency_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	sphere_wireframe_inst = sphere_wireframe_scene.get_node("sphere_curve")
	box_wireframe_inst = box_wireframe_scene.get_node("box_wireframe")
	cylinder_wireframe_inst = cylinder_wireframe_scene.get_node("cylinder_curve")

func new_wireframe_mesh() -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.material_override = MeshHelper.wireframe_mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m
	
## Adds a semi-transparent MeshInstance3D of the given shape to the given parent node.
func add_transparent_child_shape(parent: Node3D, shape: Shape3D) -> void:
	var mesh: Mesh
	match shape.get_class():
		"SphereShape3D":	
			mesh = SphereMesh.new()
			mesh.radius = 1
			mesh.height = 2

		"BoxShape3D":
				mesh = BoxMesh.new()

		"CylinderShape3D":
				mesh = CylinderMesh.new()
				mesh.height = 1
				
	var child = MeshInstance3D.new()
	child.mesh = mesh
	child.material_override = transparency_mat
	parent.add_child(child)

## Sets the mesh of the given MeshInstance3D to a wireframe of the given shape.
## Not very efficient. Only used for debug displays.
func match_wireframe_to_shape(wireframe_mesh: MeshInstance3D, shape: Shape3D) -> void:
	var m: Mesh
	match shape.get_class():
		"SphereShape3D":
			m = sphere_wireframe_inst.mesh
			wireframe_mesh.scale = Vector3(shape.radius, shape.radius, shape.radius)

		"BoxShape3D":
			m = box_wireframe_inst.mesh
			wireframe_mesh.scale = Vector3(shape.size.x, shape.size.y, shape.size.z)

		"CylinderShape3D":
			m = cylinder_wireframe_inst.mesh
			wireframe_mesh.scale = Vector3(shape.radius*2, shape.height, shape.radius*2)

	wireframe_mesh.mesh = m
