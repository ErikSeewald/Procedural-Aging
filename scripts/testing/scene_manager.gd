extends Node

@onready var ui = $UI
@onready var sub_menu: SubMenu = $SubMenu

func _ready() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		push_warning("This project is not designed for gl_compatibility rendering!
		You may see incorrect color values.")
	sub_menu.visibility_changed.connect(_on_sub_menu_visibility)

func _on_sub_menu_visibility() -> void:
	ui.visible = sub_menu.visible
