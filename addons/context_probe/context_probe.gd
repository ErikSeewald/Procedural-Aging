@tool
@icon("res://addons/context_probe/icon.svg")
extends Area3D
class_name ContextProbe

@export var params := ContextParams.new()
@onready var collision_shape: CollisionShape3D = get_node_or_null("ProbeCollisionShape")
var collision_render: MeshInstance3D
const probe_collision_layer := 9

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		if not get_node_or_null("ProbeCollisionShape"):
			collision_shape = CollisionShape3D.new()
			collision_shape.name = "ProbeCollisionShape"
			add_child(collision_shape)
			collision_shape.owner = get_tree().edited_scene_root

func _ready() -> void:
	add_to_group("context_probes")
	monitoring = true
	monitorable = true
	collision_layer = probe_collision_layer
	
	collision_render = MeshInstance3D.new()
	add_child(collision_render)
	
	collision_shape.shape.connect("changed", _update_render_mesh)
	_update_render_mesh()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 1, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	collision_render.material_override = mat

func _process(_delta: float) -> void:
	collision_render.transform = collision_shape.transform

func _update_render_mesh() -> void:
	
	var s := collision_shape.shape
	var m: Mesh
	match s.get_class():
		"SphereShape3D":
			m = SphereMesh.new()
			m.radius = s.radius
			m.height = s.radius*2
			
		"BoxShape3D":
			m = BoxMesh.new()
			m.size = s.size
			
		"CapsuleShape3D":
			m = CapsuleMesh.new()
			m.radius = s.radius
			m.height = s.height
			
		"CylinderShape3D":
			m = CylinderMesh.new()
			m.top_radius = s.radius
			m.bottom_radius = s.radius
			m.height = s.height
			
	collision_render.mesh = m
