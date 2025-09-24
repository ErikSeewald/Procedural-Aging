# Autoload for mesh related helper functions like managing debug wireframe meshes.

extends Node

var wireframe_mat: StandardMaterial3D
var transparency_mat: StandardMaterial3D

var sphere_wireframe_scene = preload("res://assets//wireframes//sphere_curve.blend").instantiate()
var box_wireframe_scene = preload("res://assets//wireframes//box_wireframe.blend").instantiate()
var cylinder_wireframe_scene = preload("res://assets//wireframes//cylinder_wireframe.blend").instantiate()

func _ready() -> void:
	wireframe_mat = StandardMaterial3D.new()
	wireframe_mat.albedo_color = Color(0, 1, 0.5, 1)
	wireframe_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wireframe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	transparency_mat = StandardMaterial3D.new()
	transparency_mat.albedo_color = Color(0, 1, 0.5, 0.05)
	transparency_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	transparency_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transparency_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func match_wireframe_to_shape(wireframe_mesh: MeshInstance3D, shape: Shape3D) -> void:
	var m: Mesh
	match shape.get_class():
		"SphereShape3D":
			var mesh_instance = sphere_wireframe_scene.get_node("sphere_curve") as MeshInstance3D
			m = mesh_instance.mesh
			wireframe_mesh.scale = Vector3(shape.radius, shape.radius, shape.radius)
			
			if wireframe_mesh.get_children().size() == 0:
				var child_m := SphereMesh.new()
				child_m.radius = 1
				child_m.height = 2
				var child_instance = MeshInstance3D.new()
				child_instance.mesh = child_m
				child_instance.material_override = transparency_mat
				wireframe_mesh.add_child(child_instance)

		"BoxShape3D":
			var mesh_instance = box_wireframe_scene.get_node("box_wireframe") as MeshInstance3D
			m = mesh_instance.mesh
			wireframe_mesh.scale = Vector3(shape.size.x, shape.size.y, shape.size.z)
			
			if wireframe_mesh.get_children().size() == 0:
				var child_m := BoxMesh.new()
				var child_instance = MeshInstance3D.new()
				child_instance.mesh = child_m
				child_instance.material_override = transparency_mat
				wireframe_mesh.add_child(child_instance)

		"CylinderShape3D":
			var mesh_instance = cylinder_wireframe_scene.get_node("cylinder_curve") as MeshInstance3D
			m = mesh_instance.mesh
			wireframe_mesh.scale = Vector3(shape.radius*2, shape.height, shape.radius*2)
			
			if wireframe_mesh.get_children().size() == 0:
				var child_m := CylinderMesh.new()
				child_m.height = 1
				var child_instance = MeshInstance3D.new()
				child_instance.mesh = child_m
				child_instance.material_override = transparency_mat
				wireframe_mesh.add_child(child_instance)
			
	wireframe_mesh.mesh = m
