extends CanvasLayer

@onready var _panel := $Panel
@onready var _list := $Panel/MarginContainer/VBoxContainer

const TOGGLE_ACTION := "ui_toggle"

var actions: Array[Dictionary] = [
	{
		"label": "Reset ages",
		"event": "reset_ages",
		"args": {}
	},
]

var checkboxes: Array[Dictionary] = [
	{
		"label": "Test multiple",
		"event": "test_multiple",
		"args": {"amount": 100}
	},
	
	{
		"label": "Show TexArray",
		"event": "show_tex_array",
		"args": {}
	},
]

func _ready() -> void:		
	_panel.visible = false
	_build_buttons()
	_build_checkboxes()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		_panel.visible = !_panel.visible
		
func _build_buttons() -> void:	
	for entry in actions:
		var label := str(entry.get("label", "Unnamed"))
		var event_name := str(entry.get("event", ""))
		var args := entry.get("args", {}) as Dictionary
		
		var button := Button.new()
		button.text = label
		button.add_theme_font_size_override("font_size", 12)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			EventBus.emit_signal_helper(event_name, args)	
		)
		
		_list.add_child(button)
		
func _build_checkboxes() -> void:
	for entry in checkboxes:
		var label := str(entry.get("label", "Unnamed"))
		var event_name := str(entry.get("event", ""))
		var args := entry.get("args", {}) as Dictionary
		
		var checkbox = CheckBox.new()
		checkbox.text = label
		checkbox.add_theme_font_size_override("font_size", 12)
		checkbox.toggled.connect(func(toggled):	
			args["toggled"] = toggled
			EventBus.emit_signal_helper(event_name, args)
		)
		
		_list.add_child(checkbox)
