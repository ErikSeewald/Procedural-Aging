extends Control
class_name SubMenu

var _input_enabled = true

func _ready() -> void:
	self.visible = false

func _input(event: InputEvent) -> void:
	if _input_enabled and event.is_action_pressed("ui_toggle"):
		self.visible = !self.visible

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled

func return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
