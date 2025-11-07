extends Node3D

@onready var age_slider: HSlider = $UI/MarginContainer/VBoxContainer/AgeSlider
@onready var cam: Camera3D = $Camera3D

## Instance to surface index
@export var objects: Dictionary[GeometryInstance3D, int]
@onready var _objects_root: Node3D = $Objects

@onready var _obj: GeometryInstance3D
var _mat: ShaderMaterial
var _rotation_axis: Vector3 = Vector3(0.0, 1.0, 0.0)
var _angle: float = 0.0
var _distance: float = 1.0

func _ready() -> void:
	# Convenience so I can leave only one visible in the editor
	for n in _objects_root.get_children():
		n.visible = true
	
	# ... but still have it work since I only set the visibility
	# of the geometry instance, not its scene root
	for o in objects.keys():
		o.visible = false
	set_object(0)
	rotate_cam(_angle)

func rotate_cam(angle: float) -> void:
	_angle = angle
	var rotation_basis = Basis(_rotation_axis, _angle)
	var initial_pos = Vector3(_distance, 0, 0)
	
	cam.transform.origin = rotation_basis * initial_pos
	
	cam.look_at(Vector3.ZERO, _rotation_axis)
	
func set_rotation_axis(index: int) -> void:
	match index:
		0: _rotation_axis = Vector3(0.0, 1.0, 0.0)
		1: _rotation_axis = Vector3(0.0, 0.0, 1.0)
		
func set_distance(distance: float) -> void:
	_distance = distance
	rotate_cam(_angle)

func set_age(age: float) -> void:
	_mat.set_shader_parameter("age", age)
	
func set_seed(new_seed: float) -> void:
	_mat.set_shader_parameter("seed", new_seed)

func set_object(index: int) -> void:
	if _obj:
		_obj.visible = false
		
	_obj = objects.keys()[index]
	_obj.visible = true
	if _obj.has_method("get_surface_override_material"):
		_mat = _obj.get_surface_override_material(objects[_obj])
	else:
		_mat = _obj.material_override
		
	age_slider.value = _mat.get_shader_parameter("age")
