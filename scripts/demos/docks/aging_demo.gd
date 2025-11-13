extends Node

@export var demo_name: String
@export var mesh_path: NodePath
@export var material_slots: Array[int]

@onready var ui: Control = $DemoUI
@onready var sub_menu: Control = get_tree().current_scene.find_child("SubMenu")
@onready var mesh: MeshInstance3D = get_node(mesh_path)
@onready var podium: Podium = $podium
@onready var demo_name_label: Label = $DemoUI/MarginContainer/VBoxContainer/DemoName
@onready var spotlight: SpotLight3D = $SpotLight3D

var _mats: Array[ShaderMaterial]
var _active = false

func _ready() -> void:
	add_to_group("aging_demos")
	ui.visible = false
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)
	podium.button_pressed.connect(_on_podium_press)
	demo_name_label.text = demo_name
	
	for i in material_slots:
		_mats.append(mesh.get_surface_override_material(i))
		
	for mat in _mats:
		seed_input.set_value_no_signal(mat.get_shader_parameter("seed"))
		age_slider.set_value_no_signal(mat.get_shader_parameter("age"))
	_connect_inputs()
	_set_input_values()

func _on_sub_menu_visibility() -> void:
	if not _active:
		ui.visible = false
	else:
		ui.visible = sub_menu.visible

func _on_podium_press() -> void:
	set_activation(!_active)
	if _active:
		for n in get_tree().get_nodes_in_group("aging_demos"):
			if n == self:
				continue
			n.set_activation(false)

func set_activation(active: bool) -> void:
	_active = active
	spotlight.visible = _active
	podium.switch_material(_active)
	if _active:
		ui.visible = sub_menu.visible
	else:
		ui.visible = false


# --- UI INPUTS ----

@onready var age_slider: HSlider = $DemoUI/MarginContainer/VBoxContainer/HSlider
@onready var seed_input: SpinBox = $DemoUI/MarginContainer/VBoxContainer/SeedInput
@onready var uv_input: HSlider = $DemoUI/MarginContainer/VBoxContainer/UVSlider
@onready var pollution_input: HSlider = $DemoUI/MarginContainer/VBoxContainer/PollutionSlider
@onready var moisture_input: HSlider = $DemoUI/MarginContainer/VBoxContainer/MoistureSlider
@onready var stability_input: HSlider = $DemoUI/MarginContainer/VBoxContainer/StabilitySlider

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
