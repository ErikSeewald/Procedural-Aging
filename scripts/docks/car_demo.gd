extends Node

@onready var car_mesh: MeshInstance3D = $old_rusty_car/Sketchfab_model/oldcar_FBX/RootNode/Object007/Car
@onready var podium: Podium = $podium
@onready var ui: Control = $UI
@onready var age_label: Label = $UI/MarginContainer/VBoxContainer/AgeLabel

var _car_mat: ShaderMaterial

func _ready() -> void:
	ui.visible = false
	podium.button_pressed.connect(_on_podium_press)
	_car_mat = car_mesh.get_surface_override_material(1)

func _on_podium_press() -> void:
	ui.visible = !ui.visible
	
func set_age(age: float) -> void:
	age_label.text = "Age: " + str(age)
	_car_mat.set_shader_parameter("age", age)
	
