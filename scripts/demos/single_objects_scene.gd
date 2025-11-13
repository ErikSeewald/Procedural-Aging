extends Node3D

@onready var ui: Panel = $UI
@onready var sub_menu: SubMenu = $SubMenu
@onready var cam: Camera3D = $Camera3D

## Instance to surface index
@export var objects: Dictionary[GeometryInstance3D, Array]
@onready var _objects_root: Node3D = $Objects

@onready var _obj: GeometryInstance3D
var _mats: Array[ShaderMaterial]
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
	
	ui.visible = false
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)
	_connect_inputs()
	
func _on_sub_menu_visibility() -> void:
	ui.visible = sub_menu.visible

func rotate_cam(angle: float) -> void:
	_angle = angle
	var rotation_basis = Basis(_rotation_axis, _angle)
	cam.transform.origin = rotation_basis * Vector3(_distance, 0, 0)
	cam.look_at(Vector3.ZERO, _rotation_axis)
	
func set_rotation_axis(index: int) -> void:
	match index:
		0: _rotation_axis = Vector3(0.0, 1.0, 0.0)
		1: _rotation_axis = Vector3(0.0, 0.0, 1.0)
		
func set_distance(distance: float) -> void:
	_distance = distance
	rotate_cam(_angle)

func set_object(index: int) -> void:
	_mats.clear()
	if _obj:
		_obj.visible = false
		
	_obj = objects.keys()[index]
	_obj.visible = true
	if _obj.has_method("get_surface_override_material"):
		for i in (objects[_obj]):
			_mats.append(_obj.get_surface_override_material(i))
	else:
		_mats[0] = _obj.material_override
		
	_set_input_values()



# --- UI INPUTS ----

@onready var age_slider: HSlider = $UI/MarginContainer/VBoxContainer/AgeSlider
@onready var seed_input: SpinBox = $UI/MarginContainer/VBoxContainer/SeedInput
@onready var uv_input: HSlider = $UI/MarginContainer/VBoxContainer/UVSlider
@onready var pollution_input: HSlider = $UI/MarginContainer/VBoxContainer/PollutionSlider
@onready var moisture_input: HSlider = $UI/MarginContainer/VBoxContainer/MoistureSlider
@onready var stability_input: HSlider = $UI/MarginContainer/VBoxContainer/StabilitySlider

func _set_input_values() -> void:
	for mat in _mats:
		age_slider.value = mat.get_shader_parameter("age")
		seed_input.value = mat.get_shader_parameter("seed")
		uv_input.value = mat.get_shader_parameter("uv_and_heat")
		pollution_input.value = mat.get_shader_parameter("pollution")
		moisture_input.value = mat.get_shader_parameter("moisture")
		stability_input.value = mat.get_shader_parameter("paint_stability")

func _connect_inputs() -> void:
	age_slider.value_changed.connect(func(v): _connect_single("age", v))
	seed_input.value_changed.connect(func(v): _connect_single("seed", v))
	uv_input.value_changed.connect(func(v): _connect_single("uv_and_heat", v))
	pollution_input.value_changed.connect(func(v): _connect_single("pollution", v))
	moisture_input.value_changed.connect(func(v): _connect_single("moisture", v))
	stability_input.value_changed.connect(func(v): _connect_single("paint_stability", v))
	
func _connect_single(key: String, value) -> void:
	for mat in _mats:
		mat.set_shader_parameter(key, value)
