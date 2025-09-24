extends CanvasLayer

@onready var _panel := $Panel
@onready var _list := $Panel/MarginContainer/VBoxContainer

const TOGGLE_ACTION := "ui_toggle"

@warning_ignore("unused_signal")
signal reset_ages

@warning_ignore("unused_signal")
signal switch_scene

@warning_ignore("unused_signal")
signal test_multiple

@warning_ignore("unused_signal")
signal show_tex_array

@warning_ignore("unused_signal")
signal show_probes

var buttons: Array[Dictionary] = [
	{
		"label": "Reset ages",
		"event": "reset_ages",
		"args": {}
	},
	
	{
		"label": "Switch scene",
		"event": "switch_scene",
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
	
	{
		"label": "Show Probes",
		"event": "show_probes",
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
	for entry in  buttons:
		var button := Button.new()
		_build_entry(entry, button)
		
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): emit_signal(entry["event"], entry["args"]))
		
func _build_checkboxes() -> void:
	for entry in checkboxes:
		var checkbox = CheckBox.new()
		_build_entry(entry, checkbox)
		
		var args := entry["args"] as Dictionary
		checkbox.toggled.connect(func(toggled):	
			args["toggled"] = toggled
			emit_signal(entry["event"], entry["args"])
		)
		
## Builds up the given base object (Button or Checkbox) with the attributes
## from the given entry dict and adds it to _list.
func _build_entry(entry: Dictionary, obj_base) -> void:
	var label := str(entry["label"])
	obj_base.text = label
	obj_base.add_theme_font_size_override("font_size", 12)
	_list.add_child(obj_base)
