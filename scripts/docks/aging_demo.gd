extends Node

@export var demo_name: String
@export var mesh_path: NodePath
@export var material_slot: int

@onready var mesh: MeshInstance3D = get_node(mesh_path)
@onready var podium: Podium = $podium
@onready var ui: Control = $DemoUI
@onready var age_label: Label = $DemoUI/MarginContainer/VBoxContainer/AgeLabel
@onready var demo_name_label: Label = $DemoUI/MarginContainer/VBoxContainer/DemoName
@onready var age_slider: HSlider = $DemoUI/MarginContainer/VBoxContainer/HSlider
@onready var spotlight: SpotLight3D = $SpotLight3D

var _mat: ShaderMaterial

var _active = false

func _ready() -> void:
	add_to_group("aging_demos")
	ui.visible = false
	demo_name_label.text = demo_name
	age_slider.value_changed.connect(set_age)
	podium.button_pressed.connect(_on_podium_press)
	_mat = mesh.get_surface_override_material(material_slot)
	age_slider.set_value_no_signal(_mat.get_shader_parameter("age"))

func _on_podium_press() -> void:
	set_activation(!_active)
	if _active:
		for n in get_tree().get_nodes_in_group("aging_demos"):
			if n == self:
				continue
			n.set_activation(false)

func set_activation(active: bool) -> void:
	_active = active
	ui.visible = _active
	spotlight.visible = _active
	podium.switch_material(_active)

func set_age(age: float) -> void:
	_mat.set_shader_parameter("age", age)
